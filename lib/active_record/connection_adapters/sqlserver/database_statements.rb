module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module DatabaseStatements
        def select_rows(sql, name = nil, binds = [])
          do_exec_query sql, name, binds, fetch: :rows
        end

        def execute(sql, name = nil)
          if id_insert_table_name = query_requires_identity_insert?(sql)
            with_identity_insert_enabled(id_insert_table_name) { do_execute(sql, name) }
          else
            do_execute(sql, name)
          end
        end

        def exec_query(sql, name = 'SQL', binds = [], sqlserver_options = {})
          if id_insert_table_name = sqlserver_options[:insert] ? query_requires_identity_insert?(sql) : nil
            with_identity_insert_enabled(id_insert_table_name) { do_exec_query(sql, name, binds) }
          elsif update_sql?(sql)
            sql = strip_ident_from_update(sql)
            do_exec_query(sql, name, binds)
          else
            do_exec_query(sql, name, binds)
          end
        end

        # The abstract adapter ignores the last two parameters also
        def exec_insert(sql, name, binds, _pk = nil, _sequence_name = nil)
          exec_query sql, name, binds, insert: true
        end

        def exec_delete(sql, name, binds)
          sql << '; SELECT @@ROWCOUNT AS AffectedRows'
          super.rows.first.first
        end

        def exec_update(sql, name, binds)
          sql << '; SELECT @@ROWCOUNT AS AffectedRows'
          super.rows.first.first
        end

        def supports_statement_cache?
          true
        end

        def begin_db_transaction
          do_execute 'BEGIN TRANSACTION'
        end

        def commit_db_transaction
          disable_auto_reconnect { do_execute 'COMMIT TRANSACTION' }
        end

        def rollback_db_transaction
          do_execute 'IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION'
        end

        def create_savepoint(name = current_savepoint_name)
          disable_auto_reconnect { do_execute "SAVE TRANSACTION #{name}" }
        end

        def release_savepoint(name = current_savepoint_name)
        end

        def rollback_to_savepoint(name = current_savepoint_name)
          disable_auto_reconnect { do_execute "ROLLBACK TRANSACTION #{name}" }
        end

        def add_limit_offset!(_sql, _options)
          raise NotImplementedError, 'This has been moved to the SQLServerCompiler in Arel.'
        end

        def empty_insert_statement_value
          'DEFAULT VALUES'
        end

        def case_sensitive_modifier(node)
          node.acts_like?(:string) ? Arel::Nodes::Bin.new(node) : node
        end

        # === SQLServer Specific ======================================== #

        def execute_procedure(proc_name, *variables)
          vars = if variables.any? && variables.first.is_a?(Hash)
                   variables.first.map { |k, v| "@#{k} = #{quote(v)}" }
                 else
                   variables.map { |v| quote(v) }
                 end.join(', ')
          sql = "EXEC #{proc_name} #{vars}".strip
          name = 'Execute Procedure'
          log(sql, name) do
            case @connection_options[:mode]
            when :dblib
              result = @connection.execute(sql)
              result.each(as: :hash, cache_rows: true) do |row|
                r = row.with_indifferent_access
                yield(r) if block_given?
              end
              result.each.map { |row| row.is_a?(Hash) ? row.with_indifferent_access : row }
            when :odbc
              results = []
              raw_connection_run(sql) do |handle|
                get_rows = lambda do
                  rows = handle_to_names_and_values handle, fetch: :all
                  rows.each_with_index { |r, i| rows[i] = r.with_indifferent_access }
                  results << rows
                end
                get_rows.call
                get_rows.call while handle_more_results?(handle)
              end
              results.many? ? results : results.first
            end
          end
        end

        def use_database(database = nil)
          return if sqlserver_azure?
          database ||= @connection_options[:database]
          do_execute "USE #{quote_database_name(database)}" unless database.blank?
        end

        def user_options
          return {} if sqlserver_azure?
          select_rows('dbcc useroptions', 'SCHEMA').reduce(HashWithIndifferentAccess.new) do |values, row|
            if row.instance_of? Hash
              set_option = row.values[0].gsub(/\s+/, '_')
              user_value = row.values[1]
            elsif  row.instance_of? Array
              set_option = row[0].gsub(/\s+/, '_')
              user_value = row[1]
            end
            values[set_option] = user_value
            values
          end
        end

        # TODO: Rails 4 now supports isolation levels
        def user_options_dateformat
          if sqlserver_azure?
            select_value 'SELECT [dateformat] FROM [sys].[syslanguages] WHERE [langid] = @@LANGID', 'SCHEMA'
          else
            user_options['dateformat']
          end
        end

        def user_options_isolation_level
          if sqlserver_azure?
            sql = %(SELECT CASE [transaction_isolation_level]
                    WHEN 0 THEN NULL
                    WHEN 1 THEN 'READ UNCOMITTED'
                    WHEN 2 THEN 'READ COMITTED'
                    WHEN 3 THEN 'REPEATABLE READ'
                    WHEN 4 THEN 'SERIALIZABLE'
                    WHEN 5 THEN 'SNAPSHOT' END AS [isolation_level]
                    FROM [sys].[dm_exec_sessions]
                    WHERE [session_id] = @@SPID).squish
            select_value sql, 'SCHEMA'
          else
            user_options['isolation_level']
          end
        end

        def user_options_language
          if sqlserver_azure?
            select_value 'SELECT @@LANGUAGE AS [language]', 'SCHEMA'
          else
            user_options['language']
          end
        end

        def run_with_isolation_level(isolation_level)
          unless valid_isolation_levels.include?(isolation_level.upcase)
            raise ArgumentError, "Invalid isolation level, #{isolation_level}. Supported levels include #{valid_isolation_levels.to_sentence}."
          end
          initial_isolation_level = user_options_isolation_level || 'READ COMMITTED'
          do_execute "SET TRANSACTION ISOLATION LEVEL #{isolation_level}"
          begin
            yield
          ensure
            do_execute "SET TRANSACTION ISOLATION LEVEL #{initial_isolation_level}"
          end if block_given?
        end

        def newid_function
          select_value 'SELECT NEWID()'
        end

        def newsequentialid_function
          select_value 'SELECT NEWSEQUENTIALID()'
        end

        def activity_stats
          select_all %|
            SELECT
               [session_id]    = s.session_id,
               [user_process]  = CONVERT(CHAR(1), s.is_user_process),
               [login]         = s.login_name,
               [database]      = ISNULL(db_name(r.database_id), N''),
               [task_state]    = ISNULL(t.task_state, N''),
               [command]       = ISNULL(r.command, N''),
               [application]   = ISNULL(s.program_name, N''),
               [wait_time_ms]  = ISNULL(w.wait_duration_ms, 0),
               [wait_type]     = ISNULL(w.wait_type, N''),
               [wait_resource] = ISNULL(w.resource_description, N''),
               [blocked_by]    = ISNULL(CONVERT (varchar, w.blocking_session_id), ''),
               [head_blocker]  =
                    CASE
                        -- session has an active request, is blocked, but is blocking others
                        WHEN r2.session_id IS NOT NULL AND r.blocking_session_id = 0 THEN '1'
                        -- session is idle but has an open tran and is blocking others
                        WHEN r.session_id IS NULL THEN '1'
                        ELSE ''
                    END,
               [total_cpu_ms]   = s.cpu_time,
               [total_physical_io_mb]   = (s.reads + s.writes) * 8 / 1024,
               [memory_use_kb]  = s.memory_usage * 8192 / 1024,
               [open_transactions] = ISNULL(r.open_transaction_count,0),
               [login_time]     = s.login_time,
               [last_request_start_time] = s.last_request_start_time,
               [host_name]      = ISNULL(s.host_name, N''),
               [net_address]    = ISNULL(c.client_net_address, N''),
               [execution_context_id] = ISNULL(t.exec_context_id, 0),
               [request_id]     = ISNULL(r.request_id, 0),
               [workload_group] = N''
            FROM sys.dm_exec_sessions s LEFT OUTER JOIN sys.dm_exec_connections c ON (s.session_id = c.session_id)
            LEFT OUTER JOIN sys.dm_exec_requests r ON (s.session_id = r.session_id)
            LEFT OUTER JOIN sys.dm_os_tasks t ON (r.session_id = t.session_id AND r.request_id = t.request_id)
            LEFT OUTER JOIN
            (SELECT *, ROW_NUMBER() OVER (PARTITION BY waiting_task_address ORDER BY wait_duration_ms DESC) AS row_num
                FROM sys.dm_os_waiting_tasks
            ) w ON (t.task_address = w.waiting_task_address) AND w.row_num = 1
            LEFT OUTER JOIN sys.dm_exec_requests r2 ON (r.session_id = r2.blocking_session_id)
            WHERE db_name(r.database_id) = '#{current_database}'
            ORDER BY s.session_id|
        end

        # === SQLServer Specific (Rake/Test Helpers) ==================== #

        def recreate_database
          remove_database_connections_and_rollback do
            do_execute "EXEC sp_MSforeachtable 'DROP TABLE ?'"
          end
        end

        def recreate_database!(database = nil)
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
            do_execute "DROP DATABASE #{quote_database_name(database)}"
          rescue ActiveRecord::StatementInvalid => err
            if err.message =~ /because it is currently in use/i
              raise if retry_count >= max_retries
              retry_count += 1
              remove_database_connections_and_rollback(database)
              retry
            elsif err.message =~ /does not exist/i
              nil
            else
              raise
            end
          end
        end

        def create_database(database, collation = @connection_options[:collation])
          if collation
            do_execute "CREATE DATABASE #{quote_database_name(database)} COLLATE #{collation}"
          else
            do_execute "CREATE DATABASE #{quote_database_name(database)}"
          end
        end

        def current_database
          select_value 'SELECT DB_NAME()'
        end

        def charset
          select_value "SELECT SERVERPROPERTY('SqlCharSetName')"
        end

        protected

        def select(sql, name = nil, binds = [])
          exec_query(sql, name, binds)
        end

        def sql_for_insert(sql, pk, id_value, sequence_name, binds)
          sql =
            if pk
              sql.insert(sql.index(/ (DEFAULT )?VALUES/), " OUTPUT inserted.#{pk}")
            else
              "#{sql}; SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident"
            end
          super
        end

        # === SQLServer Specific ======================================== #

        def valid_isolation_levels
          ['READ COMMITTED', 'READ UNCOMMITTED', 'REPEATABLE READ', 'SERIALIZABLE', 'SNAPSHOT']
        end

        # === SQLServer Specific (Executing) ============================ #

        def do_execute(sql, name = 'SQL')
          log(sql, name) do
            with_sqlserver_error_handling { raw_connection_do(sql) }
          end
        end

        def do_exec_query(sql, name, binds, options = {})
          # This allows non-AR code to utilize the binds
          # handling code, e.g. select_rows()
          if options[:fetch] != :rows
            options[:ar_result] = true
          end

          explaining = name == 'EXPLAIN'
          names_and_types = []
          params = []
          binds.each_with_index do |(column, value), index|
            ar_column = column.is_a?(ActiveRecord::ConnectionAdapters::Column)
            next if ar_column && column.sql_type == 'timestamp'
            v = value
            names_and_types << if ar_column
                                 if column.is_integer? && value.present?
                                   v = value.to_i
                                   # Reset the casted value to the bind as required by Rails 4.1
                                   binds[index] = [column, v]
                                 end
                                 "@#{index} #{column.sql_type_for_statement}"
                               elsif column.acts_like?(:string)
                                 "@#{index} nvarchar(max)"
                               elsif column.is_a?(Fixnum)
                                 v = value.to_i
                                 "@#{index} int"
                               else
                                 raise 'Unknown bind columns. We can account for this.'
                               end
            quoted_value = ar_column ? quote(v, column) : quote(v, nil)
            params << (explaining ? quoted_value : "@#{index} = #{quoted_value}")
          end
          if explaining
            params.each_with_index do |param, index|
              substitute_at_finder = /(@#{index})(?=(?:[^']|'[^']*')*$)/ # Finds unquoted @n values.
              sql.sub! substitute_at_finder, param
            end
          else
            sql = "EXEC sp_executesql #{quote(sql)}"
            sql << ", #{quote(names_and_types.join(', '))}, #{params.join(', ')}" unless binds.empty?
          end
          raw_select sql, name, binds, options
        end

        def raw_connection_do(sql)
          case @connection_options[:mode]
          when :dblib
            @connection.execute(sql).do
          when :odbc
            @connection.do(sql)
          end
        ensure
          @update_sql = false
        end

        # === SQLServer Specific (Selecting) ============================ #

        def raw_select(sql, name = 'SQL', binds = [], options = {})
          log(sql, name, binds) { _raw_select(sql, options) }
        end

        def _raw_select(sql, options = {})
          handle = raw_connection_run(sql)
          handle_to_names_and_values(handle, options)
        ensure
          finish_statement_handle(handle)
        end

        def raw_connection_run(sql)
          with_sqlserver_error_handling do
            case @connection_options[:mode]
            when :dblib
              @connection.execute(sql)
            when :odbc
              block_given? ? @connection.run_block(sql) { |handle| yield(handle) } : @connection.run(sql)
            end
          end
        end

        def handle_more_results?(handle)
          case @connection_options[:mode]
          when :dblib
          when :odbc
            handle.more_results
          end
        end

        def handle_to_names_and_values(handle, options = {})
          case @connection_options[:mode]
          when :dblib
            handle_to_names_and_values_dblib(handle, options)
          when :odbc
            handle_to_names_and_values_odbc(handle, options)
          end
        end

        def handle_to_names_and_values_dblib(handle, options = {})
          query_options = {}.tap do |qo|
            qo[:timezone] = ActiveRecord::Base.default_timezone || :utc
            qo[:as] = (options[:ar_result] || options[:fetch] == :rows) ? :array : :hash
          end
          results = handle.each(query_options)
          columns = lowercase_schema_reflection ? handle.fields.map { |c| c.downcase } : handle.fields
          options[:ar_result] ? ActiveRecord::Result.new(columns, results) : results
        end

        def handle_to_names_and_values_odbc(handle, options = {})
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

        def finish_statement_handle(handle)
          case @connection_options[:mode]
          when :dblib
            handle.cancel if handle
          when :odbc
            handle.drop if handle && handle.respond_to?(:drop) && !handle.finished?
          end
          handle
        end
      end
    end
  end
end
