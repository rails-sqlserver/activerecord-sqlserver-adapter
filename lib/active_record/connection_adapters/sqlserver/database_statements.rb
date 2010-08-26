module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module DatabaseStatements

        def select_rows(sql, name = nil)
          raw_select(sql,name).first.last
        end

        def execute(sql, name = nil, skip_logging = false)
          if table_name = query_requires_identity_insert?(sql)
            with_identity_insert_enabled(table_name) { do_execute(sql,name) }
          else
            do_execute(sql,name)
          end
        end

        def outside_transaction?
          info_schema_query { select_value("SELECT @@TRANCOUNT") == 0 }
        end

        def begin_db_transaction
          do_execute "BEGIN TRANSACTION"
        end

        def commit_db_transaction
          do_execute "COMMIT TRANSACTION"
        end

        def rollback_db_transaction
          do_execute "ROLLBACK TRANSACTION" rescue nil
        end

        def create_savepoint
          do_execute "SAVE TRANSACTION #{current_savepoint_name}"
        end

        def release_savepoint
        end

        def rollback_to_savepoint
          do_execute "ROLLBACK TRANSACTION #{current_savepoint_name}"
        end

        def add_limit_offset!(sql, options)
          raise NotImplementedError, 'This has been moved to the SQLServerCompiler in Arel.'
        end

        def empty_insert_statement_value
          "DEFAULT VALUES"
        end

        def case_sensitive_equality_operator
          cs_equality_operator
        end

        def limited_update_conditions(where_sql, quoted_table_name, quoted_primary_key)
          match_data = where_sql.match(/^(.*?[\]\) ])WHERE[\[\( ]/)
          limit = match_data[1]
          where_sql.sub!(limit,'')
          "WHERE #{quoted_primary_key} IN (SELECT #{limit} #{quoted_primary_key} FROM #{quoted_table_name} #{where_sql})"
        end
        
        # === SQLServer Specific ======================================== #
        
        def execute_procedure(proc_name, *variables)
          vars = variables.map{ |v| quote(v) }.join(', ')
          sql = "EXEC #{proc_name} #{vars}".strip
          select(sql,'Execute Procedure').inject([]) do |results,row|
            if row.kind_of?(Array)
              results << row.inject([]) { |rs,r| rs << r.with_indifferent_access }
            else
              results << row.with_indifferent_access
            end
          end
        end
        
        def use_database(database=nil)
          database ||= @connection_options[:database]
          do_execute "USE #{quote_table_name(database)}" unless database.blank?
        end
        
        def user_options
          info_schema_query do
            select_rows("dbcc useroptions").inject(HashWithIndifferentAccess.new) do |values,row| 
              set_option = row[0].gsub(/\s+/,'_')
              user_value = row[1]
              values[set_option] = user_value
              values
            end
          end
        end

        def run_with_isolation_level(isolation_level)
          raise ArgumentError, "Invalid isolation level, #{isolation_level}. Supported levels include #{valid_isolation_levels.to_sentence}." if !valid_isolation_levels.include?(isolation_level.upcase)
          initial_isolation_level = user_options[:isolation_level] || "READ COMMITTED"
          do_execute "SET TRANSACTION ISOLATION LEVEL #{isolation_level}"
          begin
            yield 
          ensure
            do_execute "SET TRANSACTION ISOLATION LEVEL #{initial_isolation_level}"
          end if block_given?
        end
        
        # === SQLServer Specific (Rake/Test Helpers) ==================== #
        
        def recreate_database
          remove_database_connections_and_rollback do
            do_execute "EXEC sp_MSforeachtable 'DROP TABLE ?'"
          end
        end

        def recreate_database!(database=nil)
          current_db = current_database
          database ||= current_db
          this_db = database.to_s == current_db
          do_execute 'USE master' if this_db
          drop_database(database)
          create_database(database)
        ensure
          use_database(current_db) if this_db
        end

        def drop_database(database)
          retry_count = 0
          max_retries = 1
          begin
            do_execute "DROP DATABASE #{quote_table_name(database)}"
          rescue ActiveRecord::StatementInvalid => err
            if err.message =~ /because it is currently in use/i
              raise if retry_count >= max_retries
              retry_count += 1
              remove_database_connections_and_rollback(database)
              retry
            else
              raise
            end
          end
        end

        def create_database(database)
          do_execute "CREATE DATABASE #{quote_table_name(database)}"
        end

        def current_database
          select_value 'SELECT DB_NAME()'
        end
        
        def charset
          select_value "SELECT SERVERPROPERTY('SqlCharSetName')"
        end
        
        
        protected
        
        def select(sql, name = nil)
          fields_and_row_sets = raw_select(sql,name)
          final_result_set = fields_and_row_sets.inject([]) do |rs,fields_and_rows|
            fields, rows = fields_and_rows
            rs << zip_fields_and_rows(fields,rows)
          end
          final_result_set.many? ? final_result_set : final_result_set.first
        end
        
        def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
          super || select_value("SELECT SCOPE_IDENTITY() AS Ident")
        end
        
        def update_sql(sql, name = nil)
          execute(sql, name)
          select_value('SELECT @@ROWCOUNT AS AffectedRows')
        end
        
        # === SQLServer Specific ======================================== #
        
        def valid_isolation_levels
          ["READ COMMITTED", "READ UNCOMMITTED", "REPEATABLE READ", "SERIALIZABLE", "SNAPSHOT"]
        end
        
        def zip_fields_and_rows(fields, rows)
          rows.inject([]) do |results,row|
            row_hash = {}
            fields.each_with_index do |f, i|
              row_hash[f] = row[i]
            end
            results << row_hash
          end
        end
        
        # === SQLServer Specific (Executing) ============================ #

        def do_execute(sql, name = nil)
          name ||= 'EXECUTE'
          log(sql, name) do
            with_auto_reconnect { raw_connection_do(sql) }
          end
        end
        
        def raw_connection_do(sql)
          case connection_mode
          when :odbc
            raw_connection.do(sql)
          else :adonet
            raw_connection.create_command.tap{ |cmd| cmd.command_text = sql }.execute_non_query
          end
        end
        
        # === SQLServer Specific (Selecting) ============================ #

        def raw_select(sql, name = nil)
          fields_and_row_sets = []
          log(sql,name) do
            begin
              handle = raw_connection_run(sql)
              loop do
                fields_and_rows = case connection_mode
                                  when :odbc
                                    handle_to_fields_and_rows_odbc(handle)
                                  when :adonet
                                    handle_to_fields_and_rows_adonet(handle)
                                  end
                fields_and_row_sets << fields_and_rows
                break unless handle_more_results?(handle)
              end
            ensure
              finish_statement_handle(handle)
            end
          end
          fields_and_row_sets
        end
        
        def raw_connection_run(sql)
          with_auto_reconnect do
            case connection_mode
            when :odbc
              block_given? ? raw_connection.run_block(sql) { |handle| yield(handle) } : raw_connection.run(sql)
            else :adonet
              raw_connection.create_command.tap{ |cmd| cmd.command_text = sql }.execute_reader
            end
          end
        end
        
        def handle_more_results?(handle)
          case connection_mode
          when :odbc
            handle.more_results
          when :adonet
            handle.next_result
          end
        end

        def handle_to_fields_and_rows_odbc(handle)
          fields = handle.columns(true).map { |c| c.name }
          results = handle.inject([]) do |rows,row|
            rows << row.inject([]) { |values,value| values << value }
          end
          rows = results.inject([]) do |rows,row|
            row.each_with_index do |value, i|
              if value.respond_to?(:to_sqlserver_string)
                row[i] = value.to_sqlserver_string
              end
            end
            rows << row
          end
          [fields,rows]
        end

        def handle_to_fields_and_rows_adonet(handle)
          if handle.has_rows
            fields = []
            rows = []
            fields_named = false
            while handle.read
              row = []
              handle.visible_field_count.times do |row_index|
                value = handle.get_value(row_index)
                value = if value.is_a? System::String
                          value.to_s
                        elsif value.is_a? System::DBNull
                          nil
                        elsif value.is_a? System::DateTime
                          value.to_string("yyyy-MM-dd HH:MM:ss.fff").to_s
                        else
                          value
                        end
                row << value
                fields << handle.get_name(row_index).to_s unless fields_named
              end
              rows << row
              fields_named = true
            end
          else
            fields, rows = [], []
          end
          [fields,rows]
        end
        
        def finish_statement_handle(handle)
          case connection_mode
          when :odbc
            handle.drop if handle && handle.respond_to?(:drop) && !handle.finished?
          when :adonet
            handle.close if handle && handle.respond_to?(:close) && !handle.is_closed
            handle.dispose if handle && handle.respond_to?(:dispose)
          end
          handle
        end
        
      end
    end
  end
end
