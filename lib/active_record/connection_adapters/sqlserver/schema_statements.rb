# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module SchemaStatements
        def create_table(table_name, **options)
          res = super
          clear_cache!
          res
        end

        def drop_table(*table_names, **options)
          table_names.each do |table_name|
            # Mimic CASCADE option as best we can.
            if options[:force] == :cascade
              execute_procedure(:sp_fkeys, pktable_name: table_name).each do |fkdata|
                fktable = fkdata["FKTABLE_NAME"]
                fkcolmn = fkdata["FKCOLUMN_NAME"]
                pktable = fkdata["PKTABLE_NAME"]
                pkcolmn = fkdata["PKCOLUMN_NAME"]
                remove_foreign_key fktable, name: fkdata["FK_NAME"]
                execute "DELETE FROM #{quote_table_name(fktable)} WHERE #{quote_column_name(fkcolmn)} IN ( SELECT #{quote_column_name(pkcolmn)} FROM #{quote_table_name(pktable)} )"
              end
            end
            if options[:if_exists] && version_year < 2016
              execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = #{quote(table_name)}) DROP TABLE #{quote_table_name(table_name)}", "SCHEMA"
            else
              super
            end
          end
        end

        def indexes(table_name)
          data = begin
            select("EXEC sp_helpindex #{quote(table_name)}", "SCHEMA")
          rescue
            []
          end

          data.reduce([]) do |indexes, index|
            if index["index_description"].match?(/primary key/)
              indexes
            else
              name = index["index_name"]
              unique = index["index_description"].match?(/unique/)
              where = select_value("SELECT [filter_definition] FROM sys.indexes WHERE name = #{quote(name)}", "SCHEMA")
              include_columns = index_include_columns(table_name, name)
              orders = {}
              columns = []

              index["index_keys"].split(",").each do |column|
                column.strip!

                if column.end_with?("(-)")
                  column.gsub! "(-)", ""
                  orders[column] = :desc
                end

                columns << column
              end

              indexes << IndexDefinition.new(table_name, name, unique, columns, where: where, orders: orders, include: include_columns.presence)
            end
          end
        end

        def index_include_columns(table_name, index_name)
          sql = <<~SQL
            SELECT
                ic.index_id,
                c.name AS column_name
            FROM
                sys.indexes i
            JOIN
                sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
            JOIN
                sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
            WHERE
                i.object_id = OBJECT_ID('#{table_name}')
                AND i.name = '#{index_name}'
                AND ic.is_included_column = 1;
          SQL

          select_all(sql, "SCHEMA").map { |row| row["column_name"] }
        end

        def columns(table_name)
          return [] if table_name.blank?

          column_definitions(table_name).map do |ci|
            sqlserver_options = ci.slice :ordinal_position, :is_primary, :is_identity, :table_name
            sql_type_metadata = fetch_type_metadata ci[:type], sqlserver_options

            new_column(
              ci[:name],
              lookup_cast_type(ci[:type]),
              ci[:default_value],
              sql_type_metadata,
              ci[:null],
              ci[:default_function],
              ci[:collation],
              nil,
              sqlserver_options
            )
          end
        end

        def new_column(name, cast_type, default, sql_type_metadata, null, default_function = nil, collation = nil, comment = nil, sqlserver_options = {})
          SQLServer::Column.new(
            name,
            cast_type,
            default,
            sql_type_metadata,
            null,
            default_function,
            collation: collation,
            comment: comment,
            **sqlserver_options
          )
        end

        def primary_keys(table_name)
          primaries = primary_keys_select(table_name)
          primaries.present? ? primaries : identity_columns(table_name).map(&:name)
        end

        def primary_keys_select(table_name)
          identifier = database_prefix_identifier(table_name)
          database = identifier.fully_qualified_database_quoted
          sql = %(
            SELECT #{lowercase_schema_reflection_sql("KCU.COLUMN_NAME")} AS [name]
            FROM #{database}.INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU
            LEFT OUTER JOIN #{database}.INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
              ON KCU.CONSTRAINT_NAME = TC.CONSTRAINT_NAME
              AND KCU.CONSTRAINT_NAME = TC.CONSTRAINT_NAME
              AND KCU.CONSTRAINT_CATALOG = TC.CONSTRAINT_CATALOG
              AND KCU.CONSTRAINT_SCHEMA = TC.CONSTRAINT_SCHEMA
              AND TC.CONSTRAINT_TYPE = N'PRIMARY KEY'
            WHERE KCU.TABLE_NAME = #{prepared_statements ? "@0" : quote(identifier.object)}
            AND KCU.TABLE_SCHEMA = #{if identifier.schema.blank?
                                       "schema_name()"
                                     else
                                       (prepared_statements ? "@1" : quote(identifier.schema))
                                     end}
            AND TC.CONSTRAINT_TYPE = N'PRIMARY KEY'
            ORDER BY KCU.ORDINAL_POSITION ASC
          ).gsub(/[[:space:]]/, " ")

          binds = []
          nv128 = SQLServer::Type::UnicodeVarchar.new limit: 128
          binds << Relation::QueryAttribute.new("TABLE_NAME", identifier.object, nv128)
          binds << Relation::QueryAttribute.new("TABLE_SCHEMA", identifier.schema, nv128) unless identifier.schema.blank?

          internal_exec_query(sql, "SCHEMA", binds).map { |row| row["name"] }
        end

        def rename_table(table_name, new_name, **options)
          validate_table_length!(new_name) unless options[:_uses_legacy_table_name]
          schema_cache.clear_data_source_cache!(table_name.to_s)
          schema_cache.clear_data_source_cache!(new_name.to_s)
          execute "EXEC sp_rename '#{table_name}', '#{new_name}'"
          rename_table_indexes(table_name, new_name, **options)
        end

        def remove_column(table_name, column_name, type = nil, **options)
          raise ArgumentError.new("You must specify at least one column name.  Example: remove_column(:people, :first_name)") if column_name.is_a? Array
          return if options[:if_exists] == true && !column_exists?(table_name, column_name)

          remove_check_constraints(table_name, column_name)
          remove_default_constraint(table_name, column_name)
          remove_indexes(table_name, column_name)
          execute "ALTER TABLE #{quote_table_name(table_name)} DROP COLUMN #{quote_column_name(column_name)}"
        end

        def change_column(table_name, column_name, type, options = {})
          sql_commands = []
          indexes = []

          if type == :datetime
            # If no precision then default it to 6.
            options[:precision] = 6 unless options.key?(:precision)

            # If there is precision then column must be of type 'datetime2'.
            type = :datetime2 unless options[:precision].nil?
          end

          column_object = schema_cache.columns(table_name).find { |c| c.name.to_s == column_name.to_s }
          without_constraints = options.key?(:default) || options.key?(:limit)
          default = if !options.key?(:default) && column_object
            column_object.default
          else
            options[:default]
          end

          if without_constraints || (column_object && column_object.type != type.to_sym)
            remove_default_constraint(table_name, column_name)
            indexes = indexes(table_name).select { |index| index.columns.include?(column_name.to_s) }
            remove_indexes(table_name, column_name)
          end

          sql_commands << "UPDATE #{quote_table_name(table_name)} SET #{quote_column_name(column_name)}=#{quote_default_expression(options[:default], column_object)} WHERE #{quote_column_name(column_name)} IS NULL" if !options[:null].nil? && options[:null] == false && !options[:default].nil?
          alter_command = "ALTER TABLE #{quote_table_name(table_name)} ALTER COLUMN #{quote_column_name(column_name)} #{type_to_sql(type, limit: options[:limit], precision: options[:precision], scale: options[:scale])}"
          alter_command += " COLLATE #{options[:collation]}" if options[:collation].present?
          alter_command += " NOT NULL" if !options[:null].nil? && options[:null] == false
          sql_commands << alter_command

          if without_constraints
            default = quote_default_expression(default, column_object || column_for(table_name, column_name))
            sql_commands << "ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{default_constraint_name(table_name, column_name)} DEFAULT #{default} FOR #{quote_column_name(column_name)}"
          end

          sql_commands.each { |c| execute(c) }

          # Add any removed indexes back
          indexes.each do |index|
            create_index_def = CreateIndexDefinition.new(index)
            execute schema_creation.accept(create_index_def)
          end

          clear_cache!
        end

        def change_column_default(table_name, column_name, default_or_changes)
          clear_cache!
          column = column_for(table_name, column_name)
          return unless column

          remove_default_constraint(table_name, column_name)
          default = extract_new_default_value(default_or_changes)
          execute "ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{default_constraint_name(table_name, column_name)} DEFAULT #{quote_default_expression(default, column)} FOR #{quote_column_name(column_name)}"
          clear_cache!
        end

        def rename_column(table_name, column_name, new_column_name)
          clear_cache!
          identifier = SQLServer::Utils.extract_identifiers("#{table_name}.#{column_name}")
          execute_procedure :sp_rename, identifier.quoted, new_column_name, "COLUMN"
          rename_column_indexes(table_name, column_name, new_column_name)
          clear_cache!
        end

        def rename_index(table_name, old_name, new_name)
          raise ArgumentError, "Index name '#{new_name}' on table '#{table_name}' is too long (#{new_name.length} characters); the limit is #{index_name_length} characters" if new_name.length > index_name_length

          identifier = SQLServer::Utils.extract_identifiers("#{table_name}.#{old_name}")
          execute_procedure :sp_rename, identifier.quoted, new_name, "INDEX"
        end

        def remove_index!(table_name, index_name)
          execute "DROP INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)}"
        end

        def build_change_column_definition(table_name, column_name, type, **options) # :nodoc:
          td = create_table_definition(table_name)
          cd = td.new_column_definition(column_name, type, **options)
          ChangeColumnDefinition.new(cd, column_name)
        end

        def build_change_column_default_definition(table_name, column_name, default_or_changes) # :nodoc:
          column = column_for(table_name, column_name)
          return unless column

          default = extract_new_default_value(default_or_changes)
          ChangeColumnDefaultDefinition.new(column, default)
        end

        def foreign_keys(table_name)
          identifier = SQLServer::Utils.extract_identifiers(table_name)
          fk_info = execute_procedure :sp_fkeys, nil, identifier.schema, nil, identifier.object, identifier.schema

          grouped_fk = fk_info.group_by { |row| row["FK_NAME"] }.values.each { |group| group.sort_by! { |row| row["KEY_SEQ"] } }.reverse
          grouped_fk.map do |group|
            row = group.first
            options = {
              name: row["FK_NAME"],
              on_update: extract_foreign_key_action("update", row["FK_NAME"]),
              on_delete: extract_foreign_key_action("delete", row["FK_NAME"])
            }

            if group.one?
              options[:column] = row["FKCOLUMN_NAME"]
              options[:primary_key] = row["PKCOLUMN_NAME"]
            else
              options[:column] = group.map { |row| row["FKCOLUMN_NAME"] }
              options[:primary_key] = group.map { |row| row["PKCOLUMN_NAME"] }
            end

            ForeignKeyDefinition.new(identifier.object, row["PKTABLE_NAME"], options)
          end
        end

        def extract_foreign_key_action(action, fk_name)
          case select_value("SELECT #{action}_referential_action_desc FROM sys.foreign_keys WHERE name = '#{fk_name}'")
          when "CASCADE" then :cascade
          when "SET_NULL" then :nullify
          end
        end

        def check_constraints(table_name)
          sql = <<~SQL
            select chk.name AS 'name',
                   chk.definition AS 'expression'
            from sys.check_constraints chk
            inner join sys.tables st on chk.parent_object_id = st.object_id
            where
            st.name = '#{table_name}'
          SQL

          chk_info = internal_exec_query(sql, "SCHEMA")

          chk_info.map do |row|
            options = {
              name: row["name"]
            }
            expression = row["expression"]
            expression = expression[1..-2] if expression.start_with?("(") && expression.end_with?(")")

            CheckConstraintDefinition.new(table_name, expression, options)
          end
        end

        def type_to_sql(type, limit: nil, precision: nil, scale: nil, **)
          type_limitable = %w[string integer float char nchar varchar nvarchar binary_basic].include?(type.to_s)
          limit = nil unless type_limitable

          case type.to_s
          when "integer"
            case limit
            when 1 then "tinyint"
            when 2 then "smallint"
            when 3..4, nil then "integer"
            when 5..8 then "bigint"
            else raise(ActiveRecordError, "No integer type has byte size #{limit}. Use a numeric with precision 0 instead.")
            end
          when "time" # https://learn.microsoft.com/en-us/sql/t-sql/data-types/time-transact-sql
            column_type_sql = type.to_s.dup
            if precision
              if (0..7) === precision
                column_type_sql << "(#{precision})"
              else
                raise(ActiveRecordError, "The time type has precision of #{precision}. The allowed range of precision is from 0 to 7")
              end
            end
            column_type_sql
          when "datetime2"
            column_type_sql = super
            if precision
              if (0..7) === precision
                column_type_sql << "(#{precision})"
              else
                raise(ActiveRecordError, "The datetime2 type has precision of #{precision}. The allowed range of precision is from 0 to 7")
              end
            end
            column_type_sql
          when "datetimeoffset"
            column_type_sql = super
            if precision
              if (0..7) === precision
                column_type_sql << "(#{precision})"
              else
                raise(ActiveRecordError, "The datetimeoffset type has precision of #{precision}. The allowed range of precision is from 0 to 7")
              end
            end
            column_type_sql
          else
            super
          end
        end

        # In SQL Server only the first column added should have the `ADD` keyword.
        def add_timestamps(table_name, **options)
          fragments = add_timestamps_for_alter(table_name, **options)
          fragments[1..].each { |fragment| fragment.sub!("ADD ", "") }
          execute "ALTER TABLE #{quote_table_name(table_name)} #{fragments.join(", ")}"
        end

        def columns_for_distinct(columns, orders)
          order_columns = orders.reject(&:blank?).map { |s|
            s = visitor.compile(s) unless s.is_a?(String)
            s.gsub(/\s+(?:ASC|DESC)\b/i, "")
              .gsub(/\s+NULLS\s+(?:FIRST|LAST)\b/i, "")
          }
            .reject(&:blank?)
            .reject { |s| columns.include?(s) }

          order_columns_aliased = order_columns.map.with_index { |column, i| "#{column} AS alias_#{i}" }

          (order_columns_aliased << super).join(", ")
        end

        def update_table_definition(table_name, base)
          SQLServer::Table.new(table_name, base)
        end

        def change_column_null(table_name, column_name, null, default = nil)
          validate_change_column_null_argument!(null)

          table_id = SQLServer::Utils.extract_identifiers(table_name)
          column_id = SQLServer::Utils.extract_identifiers(column_name)
          column = column_for(table_name, column_name)
          if !null.nil? && null == false && !default.nil?
            execute("UPDATE #{table_id} SET #{column_id}=#{quote(default)} WHERE #{column_id} IS NULL")
          end
          sql = "ALTER TABLE #{table_id} ALTER COLUMN #{column_id} #{type_to_sql column.type, limit: column.limit, precision: column.precision, scale: column.scale}"
          sql += " NOT NULL" if !null.nil? && null == false

          execute sql
        end

        def create_schema_dumper(options)
          SQLServer::SchemaDumper.create(self, options)
        end

        def create_schema(schema_name, authorization = nil)
          sql = "CREATE SCHEMA [#{schema_name}]"
          sql += " AUTHORIZATION [#{authorization}]" if authorization

          execute sql
        end

        def change_table_schema(schema_name, table_name)
          execute "ALTER SCHEMA [#{schema_name}] TRANSFER [#{table_name}]"
        end

        def drop_schema(schema_name)
          execute "DROP SCHEMA [#{schema_name}]"
        end

        # Returns an array of schema names.
        def schema_names
          sql = <<~SQL.squish
            SELECT name
             FROM sys.schemas
             WHERE
             name NOT LIKE 'db_%' AND
             name NOT IN ('INFORMATION_SCHEMA', 'sys', 'guest')
          SQL

          query_values(sql, "SCHEMA")
        end

        def quoted_include_columns_for_index(column_names) # :nodoc:
          return quote_column_name(column_names) if column_names.is_a?(Symbol)

          quoted_columns = column_names.each_with_object({}) do |name, result|
            result[name.to_sym] = quote_column_name(name).dup
          end
          add_options_for_index_columns(quoted_columns).values.join(", ")
        end

        private

        def data_source_sql(name = nil, type: nil)
          scope = quoted_scope(name, type: type)

          table_schema = lowercase_schema_reflection_sql("TABLE_SCHEMA")
          table_name = lowercase_schema_reflection_sql("TABLE_NAME")
          database = scope[:database].present? ? "#{scope[:database]}." : ""
          table_catalog = scope[:database].present? ? quote(scope[:database]) : "DB_NAME()"

          sql = "SELECT "
          sql += " CASE"
          sql += "  WHEN #{table_schema} = 'dbo' THEN #{table_name}"
          sql += "  ELSE CONCAT(#{table_schema}, '.', #{table_name})"
          sql += " END"
          sql += " FROM #{database}INFORMATION_SCHEMA.TABLES WITH (NOLOCK)"
          sql += " WHERE TABLE_CATALOG = #{table_catalog}"
          sql += " AND TABLE_SCHEMA = #{quote(scope[:schema])}" if scope[:schema]
          sql += " AND TABLE_NAME = #{quote(scope[:name])}" if scope[:name]
          sql += " AND TABLE_TYPE = #{quote(scope[:type])}" if scope[:type]
          sql += " ORDER BY #{table_name}"
          sql
        end

        def quoted_scope(name = nil, type: nil)
          identifier = SQLServer::Utils.extract_identifiers(name)

          {}.tap do |scope|
            scope[:database] = identifier.database if identifier.database
            scope[:schema] = identifier.schema || "dbo" if name.present?
            scope[:name] = identifier.object if identifier.object
            scope[:type] = type if type
          end
        end

        # === SQLServer Specific ======================================== #

        def column_definitions(table_name)
          identifier = database_prefix_identifier(table_name)
          database = identifier.fully_qualified_database_quoted
          view_exists = view_exists?(table_name)

          if view_exists
            sql = <<~SQL
              SELECT LOWER(c.COLUMN_NAME) AS [name], c.COLUMN_DEFAULT AS [default]
              FROM #{database}.INFORMATION_SCHEMA.COLUMNS c
              WHERE c.TABLE_NAME = #{quote(view_table_name(table_name))}
            SQL
            results = internal_exec_query(sql, "SCHEMA")
            default_functions = results.each.with_object({}) { |row, out| out[row["name"]] = row["default"] }.compact
          end

          sql = column_definitions_sql(database, identifier)

          binds = []
          nv128 = SQLServer::Type::UnicodeVarchar.new(limit: 128)
          binds << Relation::QueryAttribute.new("TABLE_NAME", identifier.object, nv128)
          binds << Relation::QueryAttribute.new("TABLE_SCHEMA", identifier.schema, nv128) unless identifier.schema.blank?

          results = internal_exec_query(sql, "SCHEMA", binds)
          raise ActiveRecord::StatementInvalid, "Table '#{table_name}' doesn't exist" if results.empty?

          results.map do |ci|
            col = {
              name: ci["name"],
              numeric_scale: ci["numeric_scale"],
              numeric_precision: ci["numeric_precision"],
              datetime_precision: ci["datetime_precision"],
              collation: ci["collation"],
              ordinal_position: ci["ordinal_position"],
              length: ci["length"]
            }

            col[:table_name] = view_exists ? view_table_name(table_name) : table_name
            col[:type] = column_type(ci: ci)
            col[:default_value], col[:default_function] = default_value_and_function(default: ci["default_value"],
              name: ci["name"],
              type: col[:type],
              original_type: ci["type"],
              view_exists: view_exists,
              table_name: table_name,
              default_functions: default_functions)

            col[:null] = ci["is_nullable"].to_i == 1
            col[:is_primary] = ci["is_primary"].to_i == 1

            col[:is_identity] = if [true, false].include?(ci["is_identity"])
              ci["is_identity"]
            else
              ci["is_identity"].to_i == 1
            end

            col
          end
        end

        def default_value_and_function(default:, name:, type:, original_type:, view_exists:, table_name:, default_functions:)
          if default.nil? && view_exists
            view_column = views_real_column_name(table_name, name).downcase
            default = default_functions[view_column] if view_column.present?
          end

          case default
          when nil
            [nil, nil]
          when /\A\((\w+\(\))\)\Z/
            default_function = Regexp.last_match[1]
            [nil, default_function]
          when /\A\(N'(.*)'\)\Z/m
            string_literal = SQLServer::Utils.unquote_string(Regexp.last_match[1])
            [string_literal, nil]
          when /CREATE DEFAULT/mi
            [nil, nil]
          else
            type = case type
            when /smallint|int|bigint/ then original_type
            else type
            end
            value = default.match(/\A\((.*)\)\Z/m)[1]
            value = select_value("SELECT CAST(#{value} AS #{type}) AS value", "SCHEMA")
            [value, nil]
          end
        end

        def column_type(ci:)
          case ci["type"]
          when /^bit|image|text|ntext|datetime$/
            ci["type"]
          when /^datetime2|datetimeoffset$/i
            "#{ci["type"]}(#{ci["datetime_precision"]})"
          when /^time$/i
            "#{ci["type"]}(#{ci["datetime_precision"]})"
          when /^numeric|decimal$/i
            "#{ci["type"]}(#{ci["numeric_precision"]},#{ci["numeric_scale"]})"
          when /^float|real$/i
            ci["type"]
          when /^char|nchar|varchar|nvarchar|binary|varbinary|bigint|int|smallint$/
            (ci["length"].to_i == -1) ? "#{ci["type"]}(max)" : "#{ci["type"]}(#{ci["length"]})"
          else
            ci["type"]
          end
        end

        def column_definitions_sql(database, identifier)
          schema_name = "schema_name()"

          if prepared_statements
            object_name = "@0"
            schema_name = "@1" if identifier.schema.present?
          else
            object_name = quote(identifier.object)
            schema_name = quote(identifier.schema) if identifier.schema.present?
          end

          object_id_arg = identifier.schema.present? ? "CONCAT(#{schema_name},'.',#{object_name})" : object_name

          if identifier.temporary_table?
            database = "TEMPDB"
            object_id_arg = "CONCAT('#{database}','..',#{object_name})"
          end

          %{
            SELECT
              #{lowercase_schema_reflection_sql("o.name")} AS [table_name],
              #{lowercase_schema_reflection_sql("c.name")} AS [name],
              t.name AS [type],
              d.definition AS [default_value],
              CASE
                WHEN t.name IN ('decimal', 'bigint', 'int', 'money', 'numeric', 'smallint', 'smallmoney', 'tinyint')
                THEN c.scale
              END AS [numeric_scale],
              CASE
                WHEN t.name IN ('decimal', 'bigint', 'int', 'money', 'numeric', 'smallint', 'smallmoney', 'tinyint', 'real', 'float')
                THEN c.precision
              END AS [numeric_precision],
              CASE
                WHEN t.name IN ('date', 'datetime', 'datetime2', 'datetimeoffset', 'smalldatetime', 'time')
                THEN c.scale
              END AS [datetime_precision],
              c.collation_name  AS [collation],
              ROW_NUMBER() OVER (ORDER BY c.column_id) AS [ordinal_position],
              CASE
                WHEN t.name IN ('nchar', 'nvarchar') AND c.max_length > 0
                THEN c.max_length / 2
                ELSE c.max_length
              END AS [length],
              CASE c.is_nullable
                WHEN 1
                THEN 1
              END AS [is_nullable],
              CASE
                WHEN ic.object_id IS NOT NULL
                THEN 1
              END AS [is_primary],
              c.is_identity AS [is_identity]
            FROM #{database}.sys.columns c
            INNER JOIN #{database}.sys.objects o
              ON c.object_id = o.object_id
            INNER JOIN #{database}.sys.schemas s
              ON o.schema_id = s.schema_id
            INNER JOIN #{database}.sys.types t
              ON c.system_type_id = t.system_type_id
              AND c.user_type_id = t.user_type_id
            LEFT OUTER JOIN #{database}.sys.default_constraints d
              ON c.object_id = d.parent_object_id
              AND c.default_object_id = d.object_id
            LEFT OUTER JOIN #{database}.sys.key_constraints k
              ON c.object_id = k.parent_object_id
              AND k.type = 'PK'
            LEFT OUTER JOIN #{database}.sys.index_columns ic
              ON k.parent_object_id = ic.object_id
              AND k.unique_index_id = ic.index_id
              AND c.column_id = ic.column_id
            WHERE
              o.Object_ID = Object_ID(#{object_id_arg})
              AND s.name = #{schema_name}
            ORDER BY
              c.column_id
          }.gsub(/[ \t\r\n]+/, " ").strip
        end

        def remove_columns_for_alter(table_name, *column_names, **options)
          first, *rest = column_names

          # return an array like this [DROP COLUMN col_1, col_2, col_3]. Abstract adapter joins fragments with ", "
          [remove_column_for_alter(table_name, first)] + rest.map { |column_name| quote_column_name(column_name) }
        end

        def remove_check_constraints(table_name, column_name)
          constraints = select_values "SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = '#{quote_string(table_name)}' and COLUMN_NAME = '#{quote_string(column_name)}'", "SCHEMA"
          constraints.each do |constraint|
            execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{quote_column_name(constraint)}"
          end
        end

        def remove_default_constraint(table_name, column_name)
          # If there are foreign keys in this table, we could still get back a 2D array, so flatten just in case.
          execute_procedure(:sp_helpconstraint, table_name, "nomsg").flatten.select do |row|
            row["constraint_type"] == "DEFAULT on column #{column_name}"
          end.each do |row|
            execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{row["constraint_name"]}"
          end
        end

        def remove_indexes(table_name, column_name)
          indexes(table_name).select { |index| index.columns.include?(column_name.to_s) }.each do |index|
            remove_index(table_name, name: index.name)
          end
        end

        # === SQLServer Specific (Misc Helpers) ========================= #

        # Parses just the table name from the SQL. Table name does not include database/schema/etc.
        def get_table_name(sql)
          tn = get_raw_table_name(sql)
          SQLServer::Utils.extract_identifiers(tn).object
        end

        # Parses the raw table name that is used in the SQL. Table name could include database/schema/etc.
        def get_raw_table_name(sql)
          return if sql.blank?

          s = sql.gsub(/^\s*EXEC sp_executesql N'/i, "")

          if s.match?(/^\s*INSERT INTO.*/i)
            s.split(/INSERT INTO/i)[1]
              .split(/OUTPUT INSERTED/i)[0]
              .split(/(DEFAULT)?\s+VALUES/i)[0]
              .split(/\bSELECT\b(?![^\[]*\])/i)[0]
              .match(/\s*([^(]*)/i)[0]
          elsif s.match?(/^\s*UPDATE\s+.*/i)
            s.match(/UPDATE\s+([^\(\s]+)\s*/i)[1]
          elsif s.match?(/^\s*MERGE INTO.*/i)
            s.match(/^\s*MERGE\s+INTO\s+(\[?[a-z0-9_ -]+\]?\.?\[?[a-z0-9_ -]+\]?)\s+(AS|WITH|USING)/i)[1]
          else
            s.match(/FROM[\s|\(]+((\[[^\(\]]+\])|[^\(\s]+)\s*/i)[1]
          end.strip
        end

        def default_constraint_name(table_name, column_name)
          "DF_#{table_name}_#{column_name}"
        end

        def lowercase_schema_reflection_sql(node)
          lowercase_schema_reflection ? "LOWER(#{node})" : node
        end

        # === SQLServer Specific (View Reflection) ====================== #

        def view_table_name(table_name)
          view_info = view_information(table_name)
          view_info.present? ? get_table_name(view_info["VIEW_DEFINITION"]) : table_name
        end

        def view_information(table_name)
          @view_information ||= {}

          @view_information[table_name] ||= begin
            identifier = SQLServer::Utils.extract_identifiers(table_name)
            information_query_table = identifier.database.present? ? "[#{identifier.database}].[INFORMATION_SCHEMA].[VIEWS]" : "[INFORMATION_SCHEMA].[VIEWS]"

            view_info = select_one("SELECT * FROM #{information_query_table} WITH (NOLOCK) WHERE TABLE_NAME = #{quote(identifier.object)}", "SCHEMA").to_h

            if view_info.present?
              if view_info["VIEW_DEFINITION"].blank? || view_info["VIEW_DEFINITION"].length == 4000
                view_info["VIEW_DEFINITION"] = begin
                  select_values("EXEC sp_helptext #{identifier.object_quoted}", "SCHEMA").join
                rescue
                  warn "No view definition found, possible permissions problem.\nPlease run GRANT VIEW DEFINITION TO your_user;"
                  nil
                end
              end
            end

            view_info
          end
        end

        def views_real_column_name(table_name, column_name)
          view_definition = view_information(table_name)["VIEW_DEFINITION"]
          return column_name if view_definition.blank?

          # Remove "CREATE VIEW ... AS SELECT ..." and then match the column name.
          match_data = view_definition.sub(/CREATE\s+VIEW.*AS\s+SELECT\s/, "").match(/([\w-]*)\s+AS\s+#{column_name}\W/im)
          match_data ? match_data[1] : column_name
        end

        def create_table_definition(*args, **options)
          SQLServer::TableDefinition.new(self, *args, **options)
        end
      end
    end
  end
end
