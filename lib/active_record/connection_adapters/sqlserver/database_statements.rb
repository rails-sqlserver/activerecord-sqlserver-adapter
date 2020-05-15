# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module DatabaseStatements
        READ_QUERY = ActiveRecord::ConnectionAdapters::AbstractAdapter.build_read_query_regexp(:begin, :commit, :dbcc, :explain, :save, :select, :set, :rollback) # :nodoc:
        private_constant :READ_QUERY

        def write_query?(sql) # :nodoc:
          !READ_QUERY.match?(sql)
        end

        def execute(sql, name = nil)
          if preventing_writes? && write_query?(sql)
            raise ActiveRecord::ReadOnlyError, "Write query attempted while in readonly mode: #{sql}"
          end

          materialize_transactions

          if id_insert_table_name = query_requires_identity_insert?(sql)
            with_identity_insert_enabled(id_insert_table_name) { do_execute(sql, name) }
          else
            do_execute(sql, name)
          end
        end

        def exec_query(sql, name = "SQL", binds = [], prepare: false)
          if preventing_writes? && write_query?(sql)
            raise ActiveRecord::ReadOnlyError, "Write query attempted while in readonly mode: #{sql}"
          end

          materialize_transactions

          sp_executesql(sql, name, binds, prepare: prepare)
        end

        def exec_insert(sql, name = nil, binds = [], pk = nil, _sequence_name = nil)
          if id_insert_table_name = exec_insert_requires_identity?(sql, pk, binds)
            with_identity_insert_enabled(id_insert_table_name) { super(sql, name, binds, pk) }
          else
            super(sql, name, binds, pk)
          end
        end

        def exec_delete(sql, name, binds)
          sql = sql.dup << "; SELECT @@ROWCOUNT AS AffectedRows"
          super(sql, name, binds).rows.first.first
        end

        def exec_update(sql, name, binds)
          sql = sql.dup << "; SELECT @@ROWCOUNT AS AffectedRows"
          super(sql, name, binds).rows.first.first
        end

        def begin_db_transaction
          do_execute "BEGIN TRANSACTION"
        end

        def transaction_isolation_levels
          super.merge snapshot: "SNAPSHOT"
        end

        def begin_isolated_db_transaction(isolation)
          set_transaction_isolation_level transaction_isolation_levels.fetch(isolation)
          begin_db_transaction
        end

        def set_transaction_isolation_level(isolation_level)
          do_execute "SET TRANSACTION ISOLATION LEVEL #{isolation_level}"
        end

        def commit_db_transaction
          do_execute "COMMIT TRANSACTION"
        end

        def exec_rollback_db_transaction
          do_execute "IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION"
        end

        include Savepoints

        def create_savepoint(name = current_savepoint_name)
          do_execute "SAVE TRANSACTION #{name}"
        end

        def exec_rollback_to_savepoint(name = current_savepoint_name)
          do_execute "ROLLBACK TRANSACTION #{name}"
        end

        def release_savepoint(name = current_savepoint_name)
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
            sql << " OUTPUT " << returning.map { |column| "INSERTED.#{quote_column_name(column)}" }.join(", ")
          end

          sql << " #{insert.values_list}"
          sql
        end

        # === SQLServer Specific ======================================== #

        def execute_procedure(proc_name, *variables)
          materialize_transactions

          vars = if variables.any? && variables.first.is_a?(Hash)
                   variables.first.map { |k, v| "@#{k} = #{quote(v)}" }
                 else
                   variables.map { |v| quote(v) }
                 end.join(", ")
          sql = "EXEC #{proc_name} #{vars}".strip
          name = "Execute Procedure"
          log(sql, name) do
            case @connection_options[:mode]
            when :dblib
              result = @connection.execute(sql)
              options = { as: :hash, cache_rows: true, timezone: ActiveRecord::Base.default_timezone || :utc }
              result.each(options) do |row|
                r = row.with_indifferent_access
                yield(r) if block_given?
              end
              result.each.map { |row| row.is_a?(Hash) ? row.with_indifferent_access : row }
            end
          end
        end

        def with_identity_insert_enabled(table_name)
          table_name = quote_table_name(table_name)
          set_identity_insert(table_name, true)
          yield
        ensure
          set_identity_insert(table_name, false)
        end

        def use_database(database = nil)
          return if sqlserver_azure?

          name = SQLServer::Utils.extract_identifiers(database || @connection_options[:database]).quoted
          do_execute "USE #{name}" unless name.blank?
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

        def sql_for_insert(sql, pk, binds)
          if pk.nil?
            table_name = query_requires_identity_insert?(sql)
            pk = primary_key(table_name)
          end

          sql = if pk && use_output_inserted? && !database_prefix_remote_server?
                  quoted_pk = SQLServer::Utils.extract_identifiers(pk).quoted
                  table_name ||= get_table_name(sql)
                  exclude_output_inserted = exclude_output_inserted_table_name?(table_name, sql)

                  if exclude_output_inserted
                    id_sql_type = exclude_output_inserted.is_a?(TrueClass) ? "bigint" : exclude_output_inserted
                    <<~SQL.squish
                      DECLARE @ssaIdInsertTable table (#{quoted_pk} #{id_sql_type});
                      #{sql.dup.insert sql.index(/ (DEFAULT )?VALUES/), " OUTPUT INSERTED.#{quoted_pk} INTO @ssaIdInsertTable"}
                      SELECT CAST(#{quoted_pk} AS #{id_sql_type}) FROM @ssaIdInsertTable
                    SQL
                  else
                    sql.dup.insert sql.index(/ (DEFAULT )?VALUES/), " OUTPUT INSERTED.#{quoted_pk}"
                  end
                else
                  "#{sql}; SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident"
                end
          super
        end

        # === SQLServer Specific ======================================== #

        def set_identity_insert(table_name, enable = true)
          do_execute "SET IDENTITY_INSERT #{table_name} #{enable ? 'ON' : 'OFF'}"
        rescue Exception
          raise ActiveRecordError, "IDENTITY_INSERT could not be turned #{enable ? 'ON' : 'OFF'} for table #{table_name}"
        end

        # === SQLServer Specific (Executing) ============================ #

        def do_execute(sql, name = "SQL")
          materialize_transactions

          log(sql, name) { raw_connection_do(sql) }
        end

        def sp_executesql(sql, name, binds, options = {})
          options[:ar_result] = true if options[:fetch] != :rows
          unless without_prepared_statement?(binds)
            types, params = sp_executesql_types_and_parameters(binds)
            sql = sp_executesql_sql(sql, types, params, name)
          end
          raw_select sql, name, binds, options
        end

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
          return attr.type.sqlserver_type if attr.type.respond_to?(:sqlserver_type)

          case value = attr.value_for_database
          when Numeric
            value > 2_147_483_647 ? "bigint".freeze : "int".freeze
          else
            "nvarchar(max)".freeze
          end
        end

        def sp_executesql_sql_param(attr)
          case value = attr.value_for_database
          when Type::Binary::Data,
               ActiveRecord::Type::SQLServer::Data
            quote(value)
          else
            quote(type_cast(value))
          end
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
          sql
        end

        def raw_connection_do(sql)
          case @connection_options[:mode]
          when :dblib
            result = @connection.execute(sql)

            # TinyTDS returns false instead of raising an exception if connection fails.
            # Getting around this by raising an exception ourselves while this PR
            # https://github.com/rails-sqlserver/tiny_tds/pull/469 is not released.
            raise TinyTds::Error, "failed to execute statement" if result.is_a?(FalseClass)

            result.do
          end
        ensure
          @update_sql = false
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

        def exec_insert_requires_identity?(sql, pk, binds)
          query_requires_identity_insert?(sql)
        end

        def query_requires_identity_insert?(sql)
          if insert_sql?(sql)
            table_name = get_table_name(sql)
            id_column = identity_columns(table_name).first
            # id_column && sql =~ /^\s*(INSERT|EXEC sp_executesql N'INSERT)[^(]+\([^)]*\b(#{id_column.name})\b,?[^)]*\)/i ? quote_table_name(table_name) : false
            id_column && sql =~ /^\s*(INSERT|EXEC sp_executesql N'INSERT)[^(]+\([^)]*\b(#{id_column.name})\b,?[^)]*\)/i ? table_name : false
          else
            false
          end
        end

        def insert_sql?(sql)
          !(sql =~ /^\s*(INSERT|EXEC sp_executesql N'INSERT)/i).nil?
        end

        def identity_columns(table_name)
          schema_cache.columns(table_name).select(&:is_identity?)
        end

        # === SQLServer Specific (Selecting) ============================ #

        def raw_select(sql, name = "SQL", binds = [], options = {})
          log(sql, name, binds) { _raw_select(sql, options) }
        end

        def _raw_select(sql, options = {})
          handle = raw_connection_run(sql)
          handle_to_names_and_values(handle, options)
        ensure
          finish_statement_handle(handle)
        end

        def raw_connection_run(sql)
          case @connection_options[:mode]
          when :dblib
            @connection.execute(sql)
          end
        end

        def handle_more_results?(handle)
          case @connection_options[:mode]
          when :dblib
          end
        end

        def handle_to_names_and_values(handle, options = {})
          case @connection_options[:mode]
          when :dblib
            handle_to_names_and_values_dblib(handle, options)
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

        def finish_statement_handle(handle)
          case @connection_options[:mode]
          when :dblib
            handle.cancel if handle
          end
          handle
        end
      end
    end
  end
end
