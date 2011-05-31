module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module DatabaseStatements
        
        def select_rows(sql, name = nil)
          raw_select sql, name, [], :fetch => :rows
        end

        def execute(sql, name = nil)
          if id_insert_table_name = query_requires_identity_insert?(sql)
            with_identity_insert_enabled(id_insert_table_name) { do_execute(sql,name) }
          else
            do_execute(sql,name)
          end
        end
        
        def exec_query(sql, name = 'SQL', binds = [], sqlserver_options = {})
          if id_insert_table_name = sqlserver_options[:insert] ? query_requires_identity_insert?(sql) : nil
            with_identity_insert_enabled(id_insert_table_name) { do_exec_query(sql, name, binds) }
          else
            do_exec_query(sql, name, binds)
          end
        end
        
        def exec_insert(sql, name, binds)
          exec_query sql, name, binds, :insert => true
        end
        
        def exec_delete(sql, name, binds)
          sql << "; SELECT @@ROWCOUNT AS AffectedRows"
          super.rows.first.first
        end

        def exec_update(sql, name, binds)
          sql << "; SELECT @@ROWCOUNT AS AffectedRows"
          super.rows.first.first
        end

        def outside_transaction?
          info_schema_query { select_value("SELECT @@TRANCOUNT") == 0 }
        end
        
        def supports_statement_cache?
          true
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

        def case_sensitive_modifier(node)
          node.acts_like?(:string) ? Arel::Nodes::Bin.new(node) : node
        end
        
        # === SQLServer Specific ======================================== #
        
        def execute_procedure(proc_name, *variables)
          vars = variables.map{ |v| quote(v) }.join(', ')
          sql = "EXEC #{proc_name} #{vars}".strip
          name = 'Execute Procedure'
          log(sql, name) do
            case @connection_options[:mode]
            when :dblib
              result = @connection.execute(sql)
              result.each(:as => :hash, :cache_rows => true) do |row|
                r = row.with_indifferent_access
                yield(r) if block_given?
              end
              result.each.map{ |row| row.is_a?(Hash) ? row.with_indifferent_access : row }
            when :odbc
              results = []
              raw_connection_run(sql) do |handle|
                get_rows = lambda {
                  rows = handle_to_names_and_values handle, :fetch => :all
                  rows.each_with_index { |r,i| rows[i] = r.with_indifferent_access }
                  results << rows
                }
                get_rows.call
                while handle_more_results?(handle)
                  get_rows.call
                end
              end
              results.many? ? results : results.first
            when :adonet
              results = []
              results << select(sql, name).map { |r| r.with_indifferent_access }
              results.many? ? results : results.first
            end
          end
        end
        
        def use_database(database=nil)
          return if sqlserver_azure?
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
        
        def newid_function
          select_value "SELECT NEWID()"
        end
        
        def newsequentialid_function
          select_value "SELECT NEWSEQUENTIALID()"
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
        
        def select(sql, name = nil, binds = [])
          exec_query(sql, name, binds).to_a
        end
        
        def sql_for_insert(sql, pk, id_value, sequence_name, binds)
          sql = "#{sql}; SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident"# unless binds.empty?
          super
        end

        def last_inserted_id(result)
          super || select_value("SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident")
        end
        
        # === SQLServer Specific ======================================== #
        
        def valid_isolation_levels
          ["READ COMMITTED", "READ UNCOMMITTED", "REPEATABLE READ", "SERIALIZABLE", "SNAPSHOT"]
        end
        
        # === SQLServer Specific (Executing) ============================ #

        def do_execute(sql, name = nil)
          name ||= 'EXECUTE'
          log(sql, name) do
            with_auto_reconnect { raw_connection_do(sql) }
          end
        end
        
        def do_exec_query(sql, name, binds)
          statement = quote(sql)
          names_and_types = []
          params = []
          binds.each_with_index do |(column,value),index|
            ar_column = column.is_a?(ActiveRecord::ConnectionAdapters::Column)
            next if ar_column && column.sql_type == 'timestamp'
            v = value
            names_and_types << if ar_column
                                 v = value.to_i if column.is_integer?
                                 "@#{index} #{column.sql_type_for_statement}"
                               elsif column.acts_like?(:string)
                                 "@#{index} nvarchar(max)"
                               elsif column.is_a?(Fixnum)
                                 v = value.to_i
                                 "@#{index} int"
                               else
                                 raise "Unknown bind columns. We can account for this."
                               end
            quoted_value = ar_column ? quote(v,column) : quote(v,nil)
            params << "@#{index} = #{quoted_value}"
          end
          sql = "EXEC sp_executesql #{statement}"
          sql << ", #{quote(names_and_types.join(', '))}, #{params.join(', ')}" unless binds.empty?
          raw_select sql, name, binds, :ar_result => true
        end
        
        def raw_connection_do(sql)
          case @connection_options[:mode]
          when :dblib
            @connection.execute(sql).do
          when :odbc
            @connection.do(sql)
          else :adonet
            @connection.create_command.tap{ |cmd| cmd.command_text = sql }.execute_non_query
          end
        ensure
          @update_sql = false
        end
        
        # === SQLServer Specific (Selecting) ============================ #

        def raw_select(sql, name=nil, binds=[], options={})
          log(sql,name,binds) do
            begin
              handle = raw_connection_run(sql)
              handle_to_names_and_values(handle, options)
            ensure
              finish_statement_handle(handle)
            end
          end
        end
        
        def raw_connection_run(sql)
          with_auto_reconnect do
            case @connection_options[:mode]
            when :dblib
              @connection.execute(sql)
            when :odbc
              block_given? ? @connection.run_block(sql) { |handle| yield(handle) } : @connection.run(sql)
            else :adonet
              @connection.create_command.tap{ |cmd| cmd.command_text = sql }.execute_reader
            end
          end
        end
        
        def handle_more_results?(handle)
          case @connection_options[:mode]
          when :dblib
          when :odbc
            handle.more_results
          when :adonet
            handle.next_result
          end
        end
        
        def handle_to_names_and_values(handle, options={})
          case @connection_options[:mode]
          when :dblib
            handle_to_names_and_values_dblib(handle, options)
          when :odbc
            handle_to_names_and_values_odbc(handle, options)
          when :adonet
            handle_to_names_and_values_adonet(handle, options)
          end
        end
        
        def handle_to_names_and_values_dblib(handle, options={})
          query_options = {}.tap do |qo|
            qo[:timezone] = ActiveRecord::Base.default_timezone || :utc
            qo[:as] = (options[:ar_result] || options[:fetch] == :rows) ? :array : :hash
          end
          results = handle.each(query_options)
          columns = lowercase_schema_reflection ? handle.fields.map { |c| c.downcase } : handle.fields
          options[:ar_result] ? ActiveRecord::Result.new(columns, results) : results
        end
        
        def handle_to_names_and_values_odbc(handle, options={})
          @connection.use_utc = ActiveRecord::Base.default_timezone == :utc
          if options[:ar_result]
            columns = lowercase_schema_reflection ? handle.columns(true).map { |c| c.name.downcase } : handle.columns(true).map { |c| c.name }
            rows = handle.fetch_all || []
            ActiveRecord::Result.new(columns, rows)
          else
            case options[:fetch]
            when :all
              handle.each_hash || []
            when :rows
              handle.fetch_all || []
            end
          end
        end

        def handle_to_names_and_values_adonet(handle, options={})
          if handle.has_rows
            names = []
            rows = []
            fields_named = options[:fetch] == :rows
            while handle.read
              row = []
              handle.visible_field_count.times do |row_index|
                value = handle.get_value(row_index)
                value = case value
                        when System::String
                          value.to_s
                        when System::DBNull
                          nil
                        when System::DateTime
                          value.to_string("yyyy-MM-dd HH:mm:ss.fff").to_s
                        when @@array_of_bytes ||= System::Array[System::Byte]
                          String.new(value)
                        else
                          value
                        end
                row << value
                names << handle.get_name(row_index).to_s unless fields_named
              end
              rows << row
              fields_named = true
            end
          else
            rows = []
          end
          if options[:fetch] != :rows
            names_and_values = []
            rows.each do |row|
              h = {}
              i = 0
              while i < row.size
                h[names[i]] = row[i]
                i += 1
              end
              names_and_values << h
            end
            names_and_values
          else
            rows
          end
        end
        
        def finish_statement_handle(handle)
          case @connection_options[:mode]
          when :dblib  
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
