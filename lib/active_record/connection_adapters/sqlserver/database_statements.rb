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
          # Validate and/or convert integers for :limit and :offets options.
          if options[:offset]
            raise ArgumentError, "offset should have a limit" unless options[:limit]
            unless options[:offset].kind_of?(Integer)
              if options[:offset] =~ /^\d+$/
                options[:offset] = options[:offset].to_i
              else
                raise ArgumentError, "offset should be an integer"
              end
            end
          end
          if options[:limit] && !(options[:limit].kind_of?(Integer))
            if options[:limit] =~ /^\d+$/
              options[:limit] = options[:limit].to_i
            else
              raise ArgumentError, "limit should be an integer"
            end
          end
          # The business of adding limit/offset
          if options[:limit] and options[:offset]
            tally_sql = "SELECT count(*) as TotalRows from (#{sql.sub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT#{$1} TOP 1000000000")}) tally"
            add_lock! tally_sql, options
            total_rows = select_value(tally_sql).to_i
            if (options[:limit] + options[:offset]) >= total_rows
              options[:limit] = (total_rows - options[:offset] >= 0) ? (total_rows - options[:offset]) : 0
            end
            # Make sure we do not need a special limit/offset for association limiting. http://gist.github.com/25118
            add_limit_offset_for_association_limiting!(sql,options) and return if sql_for_association_limiting?(sql)
            # Wrap the SQL query in a bunch of outer SQL queries that emulate proper LIMIT,OFFSET support.
            sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i, "SELECT * FROM (SELECT TOP #{options[:limit]} * FROM (SELECT#{$1} TOP #{options[:limit] + options[:offset]}")
            sql << ") AS tmp1"
            if options[:order]
              order = options[:order].split(',').map do |field|
                order_by_column, order_direction = field.split(" ")
                order_by_column = quote_column_name(order_by_column)
                # Investigate the SQL query to figure out if the order_by_column has been renamed.
                if sql =~ /#{Regexp.escape(order_by_column)} AS (t\d+_r\d+)/
                  # Fx "[foo].[bar] AS t4_r2" was found in the SQL. Use the column alias (ie 't4_r2') for the subsequent orderings
                  order_by_column = $1
                elsif order_by_column =~ /\w+\.\[?(\w+)\]?/
                  order_by_column = $1
                else
                  # It doesn't appear that the column name has been renamed as part of the query. Use just the column
                  # name rather than the full identifier for the outer queries.
                  order_by_column = order_by_column.split('.').last
                end
                # Put the column name and eventual direction back together
                [order_by_column, order_direction].join(' ').strip
              end.join(', ')
              sql << " ORDER BY #{change_order_direction(order)}) AS tmp2 ORDER BY #{order}"
            else
              sql << ") AS tmp2"
            end
          elsif options[:limit] && sql !~ /^\s*SELECT (@@|COUNT\()/i
            if md = sql.match(/^(\s*SELECT)(\s+DISTINCT)?(.*)/im)
              sql.replace "#{md[1]}#{md[2]} TOP #{options[:limit]}#{md[3]}"
            else
              # Account for building SQL fragments without SELECT yet. See #update_all and #limited_update_conditions.
              sql.replace "TOP #{options[:limit]} #{sql}"
            end
          end
        end

        def empty_insert_statement_value
          "DEFAULT VALUES"
        end

        def case_sensitive_equality_operator
          "COLLATE Latin1_General_CS_AS ="
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

        def do_execute(sql,name=nil)
          log(sql, name || 'EXECUTE') do
            with_auto_reconnect { raw_connection_do(sql) }
          end
        end

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
              if value.is_a? ODBC::TimeStamp
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
        
        def add_lock!(sql, options)
          # http://blog.sqlauthority.com/2007/04/27/sql-server-2005-locking-hints-and-examples/
          return unless options[:lock]
          lock_type = options[:lock] == true ? 'WITH(HOLDLOCK, ROWLOCK)' : options[:lock]
          sql.gsub! %r|LEFT OUTER JOIN\s+(.*?)\s+ON|im, "LEFT OUTER JOIN \\1 #{lock_type} ON"
          sql.gsub! %r{FROM\s([\w\[\]\.]+)}im, "FROM \\1 #{lock_type}"
        end
        
        def sql_for_association_limiting?(sql)
          if md = sql.match(/^\s*SELECT(.*)FROM.*GROUP BY.*ORDER BY.*/im)
            select_froms = md[1].split(',')
            select_froms.size == 1 && !select_froms.first.include?('*')
          end
        end
        
        def add_limit_offset_for_association_limiting!(sql, options)
          sql.replace %|
            SET NOCOUNT ON
            DECLARE @row_number TABLE (row int identity(1,1), id int)
            INSERT INTO @row_number (id)
              #{sql}
            SET NOCOUNT OFF
            SELECT id FROM (
              SELECT TOP #{options[:limit]} * FROM (
                SELECT TOP #{options[:limit] + options[:offset]} * FROM @row_number ORDER BY row
              ) AS tmp1 ORDER BY row DESC
            ) AS tmp2 ORDER BY row
          |.gsub(/[ \t\r\n]+/,' ')
        end
        
        def change_order_direction(order)
          order.split(",").collect {|fragment|
            case fragment
              when  /\bDESC\b/i     then fragment.gsub(/\bDESC\b/i, "ASC")
              when  /\bASC\b/i      then fragment.gsub(/\bASC\b/i, "DESC")
              else                  String.new(fragment).split(',').join(' DESC,') + ' DESC'
            end
          }.join(",")
        end
        
      end
    end
  end
end
