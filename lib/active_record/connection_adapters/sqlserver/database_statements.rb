# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module DatabaseStatements
        READ_QUERY = ActiveRecord::ConnectionAdapters::AbstractAdapter.build_read_query_regexp(:begin, :commit, :dbcc, :explain, :save, :select, :set, :rollback, :waitfor, :use) # :nodoc:
        private_constant :READ_QUERY

        def write_query?(sql) # :nodoc:
          !READ_QUERY.match?(sql)
        rescue ArgumentError # Invalid encoding
          !READ_QUERY.match?(sql.b)
        end

        def perform_query(raw_connection, sql, binds, type_casted_binds, prepare:, notification_payload:, batch:)
          result = if id_insert_table_name = query_requires_identity_insert?(sql)
                     with_identity_insert_enabled(id_insert_table_name, raw_connection) do
                       internal_exec_sql_query(sql, raw_connection)
                     end
                   else
                     internal_exec_sql_query(sql, raw_connection)
                   end

          verified!
          notification_payload[:row_count] = result.count
          result
        end

        def cast_result(raw_result)
          if raw_result.columns.empty?
            ActiveRecord::Result.empty
          else
            ActiveRecord::Result.new(raw_result.columns, raw_result.rows)
          end
        end

        def affected_rows(raw_result)
          raw_result.first['AffectedRows']
        end

        def raw_execute(sql, name = nil, binds = [], prepare: false, async: false, allow_retry: false, materialize_transactions: true, batch: false)
          unless binds.nil? || binds.empty?
            types, params = sp_executesql_types_and_parameters(binds)
            sql = sp_executesql_sql(sql, types, params, name)
          end

          super
        end

        def internal_exec_sql_query(sql, conn)
          handle = internal_raw_execute(sql, conn)
          handle_to_names_and_values(handle, ar_result: true)
        ensure
          finish_statement_handle(handle)
        end

        def exec_delete(sql, name = nil, binds = [])
          sql = sql.dup << "; SELECT @@ROWCOUNT AS AffectedRows"
          super(sql, name, binds)
        end

        def exec_update(sql, name = nil, binds = [])
          sql = sql.dup << "; SELECT @@ROWCOUNT AS AffectedRows"
          super(sql, name, binds)
        end

        def begin_db_transaction
          internal_execute("BEGIN TRANSACTION", "TRANSACTION", allow_retry: true, materialize_transactions: false)
        end

        def transaction_isolation_levels
          super.merge snapshot: "SNAPSHOT"
        end

        def begin_isolated_db_transaction(isolation)
          set_transaction_isolation_level(transaction_isolation_levels.fetch(isolation))
          begin_db_transaction
        end

        def set_transaction_isolation_level(isolation_level)
          internal_execute("SET TRANSACTION ISOLATION LEVEL #{isolation_level}", "TRANSACTION", allow_retry: true, materialize_transactions: false)
        end

        def commit_db_transaction
          internal_execute("COMMIT TRANSACTION", "TRANSACTION", allow_retry: false, materialize_transactions: true)
        end

        def exec_rollback_db_transaction
          internal_execute("IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION", "TRANSACTION", allow_retry: false, materialize_transactions: true)
        end

        def case_sensitive_comparison(attribute, value)
          column = column_for_attribute(attribute)

          if column.collation && !column.case_sensitive?
            attribute.eq(Arel::Nodes::Bin.new(value))
          else
            super
          end
        end

        # We should propose this change to Rails team
        def insert_fixtures_set(fixture_set, tables_to_delete = [])
          fixture_inserts = []

          fixture_set.each do |table_name, fixtures|
            fixtures.each_slice(insert_rows_length) do |batch|
              fixture_inserts << build_fixture_sql(batch, table_name)
            end
          end

          table_deletes = tables_to_delete.map { |table| "DELETE FROM #{quote_table_name table}" }
          total_sqls = Array.wrap(table_deletes + fixture_inserts)

          disable_referential_integrity do
            transaction(requires_new: true) do
              total_sqls.each do |sql|
                execute sql, "Fixtures Load"
                yield if block_given?
              end
            end
          end
        end

        def can_perform_case_insensitive_comparison_for?(column)
          column.type == :string && (!column.collation || column.case_sensitive?)
        end
        private :can_perform_case_insensitive_comparison_for?

        def default_insert_value(column)
          if column.is_identity?
            table_name = quote(quote_table_name(column.table_name))
            Arel.sql("IDENT_CURRENT(#{table_name}) + IDENT_INCR(#{table_name})")
          else
            super
          end
        end
        private :default_insert_value

        def build_insert_sql(insert) # :nodoc:
          sql = +"INSERT #{insert.into}"

          if returning = insert.send(:insert_all).returning
            returning_sql = if returning.is_a?(String)
                              returning
                            else
                              returning.map { |column| "INSERTED.#{quote_column_name(column)}" }.join(", ")
                            end
            sql << " OUTPUT #{returning_sql}"
          end

          sql << " #{insert.values_list}"
          sql
        end

        # === SQLServer Specific ======================================== #

        def execute_procedure(proc_name, *variables)
          vars = if variables.any? && variables.first.is_a?(Hash)
                   variables.first.map { |k, v| "@#{k} = #{quote(v)}" }
                 else
                   variables.map { |v| quote(v) }
                 end.join(", ")
          sql = "EXEC #{proc_name} #{vars}".strip

          log(sql, "Execute Procedure") do |notification_payload|
            with_raw_connection do |conn|
              result = internal_raw_execute(sql, conn)
              verified!
              options = { as: :hash, cache_rows: true, timezone: ActiveRecord.default_timezone || :utc }

              result.each(options) do |row|
                r = row.with_indifferent_access
                yield(r) if block_given?
              end

              result = result.each.map { |row| row.is_a?(Hash) ? row.with_indifferent_access : row }
              notification_payload[:row_count] = result.count
              result
            end
          end
        end

        def with_identity_insert_enabled(table_name, conn)
          table_name = quote_table_name(table_name)
          set_identity_insert(table_name, conn, true)
          yield
        ensure
          set_identity_insert(table_name, conn, false)
        end

        def use_database(database = nil)
          return if sqlserver_azure?

          name = SQLServer::Utils.extract_identifiers(database || @connection_parameters[:database]).quoted
          execute("USE #{name}", "SCHEMA") unless name.blank?
        end

        def user_options
          return {} if sqlserver_azure?

          rows = select_rows("DBCC USEROPTIONS WITH NO_INFOMSGS", "SCHEMA")
          rows = rows.first if rows.size == 2 && rows.last.empty?
          rows.reduce(HashWithIndifferentAccess.new) do |values, row|
            if row.instance_of? Hash
              set_option = row.values[0].gsub(/\s+/, "_")
              user_value = row.values[1]
            elsif row.instance_of? Array
              set_option = row[0].gsub(/\s+/, "_")
              user_value = row[1]
            end
            values[set_option] = user_value
            values
          end
        end

        def user_options_dateformat
          if sqlserver_azure?
            select_value "SELECT [dateformat] FROM [sys].[syslanguages] WHERE [langid] = @@LANGID", "SCHEMA"
          else
            user_options["dateformat"]
          end
        end

        def user_options_isolation_level
          if sqlserver_azure?
            sql = %(SELECT CASE [transaction_isolation_level]
                    WHEN 0 THEN NULL
                    WHEN 1 THEN 'READ UNCOMMITTED'
                    WHEN 2 THEN 'READ COMMITTED'
                    WHEN 3 THEN 'REPEATABLE READ'
                    WHEN 4 THEN 'SERIALIZABLE'
                    WHEN 5 THEN 'SNAPSHOT' END AS [isolation_level]
                    FROM [sys].[dm_exec_sessions]
                    WHERE [session_id] = @@SPID).squish
            select_value sql, "SCHEMA"
          else
            user_options["isolation_level"]
          end
        end

        def user_options_language
          if sqlserver_azure?
            select_value "SELECT @@LANGUAGE AS [language]", "SCHEMA"
          else
            user_options["language"]
          end
        end

        def newid_function
          select_value "SELECT NEWID()"
        end

        def newsequentialid_function
          select_value "SELECT NEWSEQUENTIALID()"
        end

        protected

        def sql_for_insert(sql, pk, binds, returning)
          if pk.nil?
            table_name = query_requires_identity_insert?(sql)
            pk = primary_key(table_name)
          end

          sql = if pk && use_output_inserted? && !database_prefix_remote_server?
                  table_name ||= get_table_name(sql)
                  exclude_output_inserted = exclude_output_inserted_table_name?(table_name, sql)

                  if exclude_output_inserted
                    pk_and_types = Array(pk).map do |subkey|
                      {
                        quoted: SQLServer::Utils.extract_identifiers(subkey).quoted,
                        id_sql_type: exclude_output_inserted_id_sql_type(subkey, exclude_output_inserted)
                      }
                    end

                    <<~SQL.squish
                      DECLARE @ssaIdInsertTable table (#{pk_and_types.map { |pk_and_type| "#{pk_and_type[:quoted]} #{pk_and_type[:id_sql_type]}"}.join(", ") });
                      #{sql.dup.insert sql.index(/ (DEFAULT )?VALUES/i), " OUTPUT #{ pk_and_types.map { |pk_and_type| "INSERTED.#{pk_and_type[:quoted]}" }.join(", ") } INTO @ssaIdInsertTable"}
                      SELECT #{pk_and_types.map {|pk_and_type| "CAST(#{pk_and_type[:quoted]} AS #{pk_and_type[:id_sql_type]}) #{pk_and_type[:quoted]}"}.join(", ")} FROM @ssaIdInsertTable
                    SQL
                  else
                    returning_columns = returning || Array(pk)

                    if returning_columns.any?
                      returning_columns_statements = returning_columns.map { |c| " INSERTED.#{SQLServer::Utils.extract_identifiers(c).quoted}" }
                      sql.dup.insert sql.index(/ (DEFAULT )?VALUES/i), " OUTPUT" + returning_columns_statements.join(",")
                    else
                      sql
                    end
                  end
                else
                  "#{sql}; SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident"
                end

          [sql, binds]
        end

        # === SQLServer Specific ======================================== #

        def set_identity_insert(table_name, conn, enable)
          internal_raw_execute("SET IDENTITY_INSERT #{table_name} #{enable ? 'ON' : 'OFF'}", conn , perform_do: true)
        rescue Exception
          raise ActiveRecordError, "IDENTITY_INSERT could not be turned #{enable ? 'ON' : 'OFF'} for table #{table_name}"
        end

        # === SQLServer Specific (Executing) ============================ #

        def sp_executesql_types_and_parameters(binds)
          types, params = [], []
          binds.each_with_index do |attr, index|
            attr = attr.value if attr.is_a?(Arel::Nodes::BindParam)

            types << "@#{index} #{sp_executesql_sql_type(attr)}"
            params << sp_executesql_sql_param(attr)
          end
          [types, params]
        end

        def sp_executesql_sql_type(attr)
          if attr.respond_to?(:type)
            type = attr.type.serialized? ? attr.type.subtype : attr.type

            return type.sqlserver_type if type.respond_to?(:sqlserver_type)

            if type.is_a?(ActiveRecord::Encryption::EncryptedAttributeType) && type.instance_variable_get(:@cast_type).respond_to?(:sqlserver_type)
              return type.instance_variable_get(:@cast_type).sqlserver_type
            end
          end

          value = basic_attribute_type?(attr) ? attr : attr.value_for_database

          if value.is_a?(Numeric)
            value > 2_147_483_647 ? "bigint".freeze : "int".freeze
          else
            "nvarchar(max)".freeze
          end
        end

        def sp_executesql_sql_param(attr)
          return quote(attr) if basic_attribute_type?(attr)

          case value = attr.value_for_database
          when Type::Binary::Data, ActiveRecord::Type::SQLServer::Data
            quote(value)
          else
            quote(type_cast(value))
          end
        end

        def basic_attribute_type?(type)
          type.is_a?(Symbol) ||
            type.is_a?(String) ||
            type.is_a?(Numeric) ||
            type.is_a?(Time) ||
            type.is_a?(TrueClass) ||
            type.is_a?(FalseClass) ||
            type.is_a?(NilClass)
        end

        def sp_executesql_sql(sql, types, params, name)
          if name == "EXPLAIN"
            params.each.with_index do |param, index|
              substitute_at_finder = /(@#{index})(?=(?:[^']|'[^']*')*$)/ # Finds unquoted @n values.
              sql = sql.sub substitute_at_finder, param.to_s
            end
          else
            types = quote(types.join(", "))
            params = params.map.with_index { |p, i| "@#{i} = #{p}" }.join(", ") # Only p is needed, but with @i helps explain regexp.
            sql = "EXEC sp_executesql #{quote(sql)}"
            sql += ", #{types}, #{params}" unless params.empty?
          end

          sql.freeze
        end

        # === SQLServer Specific (Identity Inserts) ===================== #

        def use_output_inserted?
          self.class.use_output_inserted
        end

        def exclude_output_inserted_table_names?
          !self.class.exclude_output_inserted_table_names.empty?
        end

        def exclude_output_inserted_table_name?(table_name, sql)
          return false unless exclude_output_inserted_table_names?

          table_name ||= get_table_name(sql)
          return false unless table_name

          self.class.exclude_output_inserted_table_names[table_name]
        end

        def exclude_output_inserted_id_sql_type(pk, exclude_output_inserted)
          return "bigint" if exclude_output_inserted.is_a?(TrueClass)
          return exclude_output_inserted[pk.to_sym] if exclude_output_inserted.is_a?(Hash)
          exclude_output_inserted
        end

        def query_requires_identity_insert?(sql)
          return false unless insert_sql?(sql)

          raw_table_name = get_raw_table_name(sql)
          id_column = identity_columns(raw_table_name).first

          id_column && sql =~ /^\s*(INSERT|EXEC sp_executesql N'INSERT)[^(]+\([^)]*\b(#{id_column.name})\b,?[^)]*\)/i ? SQLServer::Utils.extract_identifiers(raw_table_name).quoted : false
        end

        def insert_sql?(sql)
          !(sql =~ /\A\s*(INSERT|EXEC sp_executesql N'INSERT)/i).nil?
        end

        def identity_columns(table_name)
          schema_cache.columns(table_name).select(&:is_identity?)
        end

        # === SQLServer Specific (Selecting) ============================ #

        def _raw_select(sql, conn)
          handle = internal_raw_execute(sql, conn)
          handle_to_names_and_values(handle, fetch: :rows)
        ensure
          finish_statement_handle(handle)
        end

        def handle_to_names_and_values(handle, options = {})
          query_options = {}.tap do |qo|
            qo[:timezone] = ActiveRecord.default_timezone || :utc
            qo[:as] = (options[:ar_result] || options[:fetch] == :rows) ? :array : :hash
          end
          results = handle.each(query_options)

          columns = handle.fields
          # If query returns multiple result sets, only return the columns of the last one.
          columns = columns.last if columns.any? && columns.all? { |e| e.is_a?(Array) }
          columns = columns.map(&:downcase) if lowercase_schema_reflection

          options[:ar_result] ? ActiveRecord::Result.new(columns, results) : results
        end

        def finish_statement_handle(handle)
          handle.cancel if handle
          handle
        end

        # TinyTDS returns false instead of raising an exception if connection fails.
        # Getting around this by raising an exception ourselves while PR
        # https://github.com/rails-sqlserver/tiny_tds/pull/469 is not released.
        def internal_raw_execute(sql, raw_connection, perform_do: false)
          result = raw_connection.execute(sql)
          raise TinyTds::Error, "failed to execute statement" if result.is_a?(FalseClass)

          perform_do ? result.do : result
        end
      end
    end
  end
end
