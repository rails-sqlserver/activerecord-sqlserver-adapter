# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module SchemaStatements
        def native_database_types
          @native_database_types ||= initialize_native_database_types.freeze
        end

        def create_table(table_name, **options)
          res = super
          clear_cache!
          res
        end

        def drop_table(table_name, **options)
          # Mimic CASCADE option as best we can.
          if options[:force] == :cascade
            execute_procedure(:sp_fkeys, pktable_name: table_name).each do |fkdata|
              fktable = fkdata["FKTABLE_NAME"]
              fkcolmn = fkdata["FKCOLUMN_NAME"]
              pktable = fkdata["PKTABLE_NAME"]
              pkcolmn = fkdata["PKCOLUMN_NAME"]
              remove_foreign_key fktable, name: fkdata["FK_NAME"]
              do_execute "DELETE FROM #{quote_table_name(fktable)} WHERE #{quote_column_name(fkcolmn)} IN ( SELECT #{quote_column_name(pkcolmn)} FROM #{quote_table_name(pktable)} )"
            end
          end
          if options[:if_exists] && @version_year < 2016
            execute "IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = #{quote(table_name)}) DROP TABLE #{quote_table_name(table_name)}"
          else
            super
          end
        end

        def indexes(table_name)
          data = select("EXEC sp_helpindex #{quote(table_name)}", "SCHEMA") rescue []

          data.reduce([]) do |indexes, index|
            index = index.with_indifferent_access

            if index[:index_description] =~ /primary key/
              indexes
            else
              name    = index[:index_name]
              unique  = index[:index_description] =~ /unique/
              where   = select_value("SELECT [filter_definition] FROM sys.indexes WHERE name = #{quote(name)}")
              orders  = {}
              columns = []

              index[:index_keys].split(",").each do |column|
                column.strip!

                if column.ends_with?("(-)")
                  column.gsub! "(-)", ""
                  orders[column] = :desc
                end

                columns << column
              end

              indexes << IndexDefinition.new(table_name, name, unique, columns, where: where, orders: orders)
            end
          end
        end

        def columns(table_name)
          return [] if table_name.blank?

          column_definitions(table_name).map do |ci|
            sqlserver_options = ci.slice :ordinal_position, :is_primary, :is_identity, :table_name
            sql_type_metadata = fetch_type_metadata ci[:type], sqlserver_options
            new_column(
              ci[:name],
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

        def new_column(name, default, sql_type_metadata, null, default_function = nil, collation = nil, comment = nil, sqlserver_options = {})
          SQLServerColumn.new(
            name,
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
          sql = %{
            SELECT #{lowercase_schema_reflection_sql('KCU.COLUMN_NAME')} AS [name]
            FROM #{database}.INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU
            LEFT OUTER JOIN #{database}.INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
              ON KCU.CONSTRAINT_NAME = TC.CONSTRAINT_NAME
              AND KCU.CONSTRAINT_NAME = TC.CONSTRAINT_NAME
              AND KCU.CONSTRAINT_CATALOG = TC.CONSTRAINT_CATALOG
              AND KCU.CONSTRAINT_SCHEMA = TC.CONSTRAINT_SCHEMA
              AND TC.CONSTRAINT_TYPE = N'PRIMARY KEY'
            WHERE KCU.TABLE_NAME = #{prepared_statements ? '@0' : quote(identifier.object)}
            AND KCU.TABLE_SCHEMA = #{identifier.schema.blank? ? 'schema_name()' : (prepared_statements ? '@1' : quote(identifier.schema))}
            AND TC.CONSTRAINT_TYPE = N'PRIMARY KEY'
            ORDER BY KCU.ORDINAL_POSITION ASC
          }.gsub(/[[:space:]]/, " ")
          binds = []
          nv128 = SQLServer::Type::UnicodeVarchar.new limit: 128
          binds << Relation::QueryAttribute.new("TABLE_NAME", identifier.object, nv128)
          binds << Relation::QueryAttribute.new("TABLE_SCHEMA", identifier.schema, nv128) unless identifier.schema.blank?
          sp_executesql(sql, "SCHEMA", binds).map { |r| r["name"] }
        end

        def rename_table(table_name, new_name)
          do_execute "EXEC sp_rename '#{table_name}', '#{new_name}'"
          rename_table_indexes(table_name, new_name)
        end

        def remove_column(table_name, column_name, type = nil, options = {})
          raise ArgumentError.new("You must specify at least one column name.  Example: remove_column(:people, :first_name)") if column_name.is_a? Array

          remove_check_constraints(table_name, column_name)
          remove_default_constraint(table_name, column_name)
          remove_indexes(table_name, column_name)
          do_execute "ALTER TABLE #{quote_table_name(table_name)} DROP COLUMN #{quote_column_name(column_name)}"
        end

        def change_column(table_name, column_name, type, options = {})
          sql_commands = []
          indexes = []
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
          alter_command += " NOT NULL" if !options[:null].nil? && options[:null] == false
          sql_commands << alter_command
          if without_constraints
            default = quote_default_expression(default, column_object || column_for(table_name, column_name))
            sql_commands << "ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{default_constraint_name(table_name, column_name)} DEFAULT #{default} FOR #{quote_column_name(column_name)}"
          end
          # Add any removed indexes back
          indexes.each do |index|
            sql_commands << "CREATE INDEX #{quote_table_name(index.name)} ON #{quote_table_name(table_name)} (#{index.columns.map { |c| quote_column_name(c) }.join(', ')})"
          end
          sql_commands.each { |c| do_execute(c) }
          clear_cache!
        end

        def change_column_default(table_name, column_name, default_or_changes)
          clear_cache!
          column = column_for(table_name, column_name)
          return unless column

          remove_default_constraint(table_name, column_name)
          default = extract_new_default_value(default_or_changes)
          do_execute "ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{default_constraint_name(table_name, column_name)} DEFAULT #{quote_default_expression(default, column)} FOR #{quote_column_name(column_name)}"
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
          raise ArgumentError, "Index name '#{new_name}' on table '#{table_name}' is too long; the limit is #{allowed_index_name_length} characters" if new_name.length > allowed_index_name_length

          identifier = SQLServer::Utils.extract_identifiers("#{table_name}.#{old_name}")
          execute_procedure :sp_rename, identifier.quoted, new_name, "INDEX"
        end

        def remove_index!(table_name, index_name)
          do_execute "DROP INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)}"
        end

        def foreign_keys(table_name)
          identifier = SQLServer::Utils.extract_identifiers(table_name)
          fk_info = execute_procedure :sp_fkeys, nil, identifier.schema, nil, identifier.object, identifier.schema
          fk_info.map do |row|
            from_table = identifier.object
            to_table = row["PKTABLE_NAME"]
            options = {
              name: row["FK_NAME"],
              column: row["FKCOLUMN_NAME"],
              primary_key: row["PKCOLUMN_NAME"],
              on_update: extract_foreign_key_action("update", row["FK_NAME"]),
              on_delete: extract_foreign_key_action("delete", row["FK_NAME"])
            }
            ForeignKeyDefinition.new from_table, to_table, options
          end
        end

        def extract_foreign_key_action(action, fk_name)
          case select_value("SELECT #{action}_referential_action_desc FROM sys.foreign_keys WHERE name = '#{fk_name}'")
          when "CASCADE" then :cascade
          when "SET_NULL" then :nullify
          end
        end

        def type_to_sql(type, limit: nil, precision: nil, scale: nil, **)
          type_limitable = %w(string integer float char nchar varchar nvarchar).include?(type.to_s)
          limit = nil unless type_limitable
          case type.to_s
          when "integer"
            case limit
            when 1          then  "tinyint"
            when 2          then  "smallint"
            when 3..4, nil  then  "integer"
            when 5..8       then  "bigint"
            else raise(ActiveRecordError, "No integer type has byte size #{limit}. Use a numeric with precision 0 instead.")
            end
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
          else
            super
          end
        end

        def columns_for_distinct(columns, orders)
          order_columns = orders.reject(&:blank?).map { |s|
                            s = s.to_sql unless s.is_a?(String)
                            s.gsub(/\s+(?:ASC|DESC)\b/i, "")
                             .gsub(/\s+NULLS\s+(?:FIRST|LAST)\b/i, "")
                          }.reject(&:blank?).map.with_index { |column, i| "#{column} AS alias_#{i}" }

          (order_columns << super).join(", ")
        end

        def update_table_definition(table_name, base)
          SQLServer::Table.new(table_name, base)
        end

        def change_column_null(table_name, column_name, allow_null, default = nil)
          table_id = SQLServer::Utils.extract_identifiers(table_name)
          column_id = SQLServer::Utils.extract_identifiers(column_name)
          column = column_for(table_name, column_name)
          if !allow_null.nil? && allow_null == false && !default.nil?
            do_execute("UPDATE #{table_id} SET #{column_id}=#{quote(default)} WHERE #{column_id} IS NULL")
          end
          sql = "ALTER TABLE #{table_id} ALTER COLUMN #{column_id} #{type_to_sql column.type, limit: column.limit, precision: column.precision, scale: column.scale}"
          sql += " NOT NULL" if !allow_null.nil? && allow_null == false
          do_execute sql
        end

        def create_schema_dumper(options)
          SQLServer::SchemaDumper.create(self, options)
        end

        private

        def data_source_sql(name = nil, type: nil)
          scope = quoted_scope name, type: type
          table_name = lowercase_schema_reflection_sql "TABLE_NAME"
          sql = "SELECT #{table_name}"
          sql += " FROM INFORMATION_SCHEMA.TABLES WITH (NOLOCK)"
          sql += " WHERE TABLE_CATALOG = DB_NAME()"
          sql += " AND TABLE_SCHEMA = #{quote(scope[:schema])}"
          sql += " AND TABLE_NAME = #{quote(scope[:name])}" if scope[:name]
          sql += " AND TABLE_TYPE = #{quote(scope[:type])}" if scope[:type]
          sql += " ORDER BY #{table_name}"
          sql
        end

        def quoted_scope(name = nil, type: nil)
          identifier = SQLServer::Utils.extract_identifiers(name)
          {}.tap do |scope|
            scope[:schema] = identifier.schema || "dbo"
            scope[:name] = identifier.object if identifier.object
            scope[:type] = type if type
          end
        end

        # === SQLServer Specific ======================================== #

        def initialize_native_database_types
          {
            primary_key: "bigint NOT NULL IDENTITY(1,1) PRIMARY KEY",
            primary_key_nonclustered: "int NOT NULL IDENTITY(1,1) PRIMARY KEY NONCLUSTERED",
            integer: { name: "int", limit: 4 },
            bigint: { name: "bigint" },
            boolean: { name: "bit" },
            decimal: { name: "decimal" },
            money: { name: "money" },
            smallmoney: { name: "smallmoney" },
            float: { name: "float" },
            real: { name: "real" },
            date: { name: "date" },
            datetime: { name: "datetime" },
            datetime2: { name: "datetime2" },
            datetimeoffset: { name: "datetimeoffset" },
            smalldatetime: { name: "smalldatetime" },
            timestamp: { name: "datetime" },
            time: { name: "time" },
            char: { name: "char" },
            varchar: { name: "varchar", limit: 8000 },
            varchar_max: { name: "varchar(max)" },
            text_basic: { name: "text" },
            nchar: { name: "nchar" },
            string: { name: "nvarchar", limit: 4000 },
            text: { name: "nvarchar(max)" },
            ntext: { name: "ntext" },
            binary_basic: { name: "binary" },
            varbinary: { name: "varbinary", limit: 8000 },
            binary: { name: "varbinary(max)" },
            uuid: { name: "uniqueidentifier" },
            ss_timestamp: { name: "timestamp" },
            json: { name: "nvarchar(max)" }
          }
        end

        def column_definitions(table_name)
          identifier  = database_prefix_identifier(table_name)
          database    = identifier.fully_qualified_database_quoted
          view_exists = view_exists?(table_name)
          view_tblnm  = view_table_name(table_name) if view_exists

          sql = column_definitions_sql(database, identifier)

          binds = []
          nv128 = SQLServer::Type::UnicodeVarchar.new limit: 128
          binds << Relation::QueryAttribute.new("TABLE_NAME", identifier.object, nv128)
          binds << Relation::QueryAttribute.new("TABLE_SCHEMA", identifier.schema, nv128) unless identifier.schema.blank?
          results = sp_executesql(sql, "SCHEMA", binds)
          results.map do |ci|
            ci = ci.symbolize_keys
            ci[:_type] = ci[:type]
            ci[:table_name] = view_tblnm || table_name
            ci[:type] = case ci[:type]
                        when /^bit|image|text|ntext|datetime$/
                          ci[:type]
                        when /^datetime2|datetimeoffset$/i
                          "#{ci[:type]}(#{ci[:datetime_precision]})"
                        when /^time$/i
                          "#{ci[:type]}(#{ci[:datetime_precision]})"
                        when /^numeric|decimal$/i
                          "#{ci[:type]}(#{ci[:numeric_precision]},#{ci[:numeric_scale]})"
                        when /^float|real$/i
                          "#{ci[:type]}"
                        when /^char|nchar|varchar|nvarchar|binary|varbinary|bigint|int|smallint$/
                          ci[:length].to_i == -1 ? "#{ci[:type]}(max)" : "#{ci[:type]}(#{ci[:length]})"
                        else
                          ci[:type]
                        end
            ci[:default_value],
            ci[:default_function] = begin
              default = ci[:default_value]
              if default.nil? && view_exists
                default = select_value %{
                  SELECT c.COLUMN_DEFAULT
                  FROM #{database}.INFORMATION_SCHEMA.COLUMNS c
                  WHERE
                    c.TABLE_NAME = '#{view_tblnm}'
                    AND c.COLUMN_NAME = '#{views_real_column_name(table_name, ci[:name])}'
                }.squish, "SCHEMA"
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
                type = case ci[:type]
                       when /smallint|int|bigint/ then ci[:_type]
                       else ci[:type]
                       end
                value = default.match(/\A\((.*)\)\Z/m)[1]
                value = select_value("SELECT CAST(#{value} AS #{type}) AS value", "SCHEMA")
                [value, nil]
              end
            end
            ci[:null] = ci[:is_nullable].to_i == 1
            ci.delete(:is_nullable)
            ci[:is_primary] = ci[:is_primary].to_i == 1
            ci[:is_identity] = ci[:is_identity].to_i == 1 unless [TrueClass, FalseClass].include?(ci[:is_identity].class)
            ci
          end
        end

        def column_definitions_sql(database, identifier)
          object_name = prepared_statements ? "@0" : quote(identifier.object)
          schema_name = if identifier.schema.blank?
                          "schema_name()"
                        else
                          prepared_statements ? "@1" : quote(identifier.schema)
                        end

          %{
            SELECT
              #{lowercase_schema_reflection_sql('o.name')} AS [table_name],
              #{lowercase_schema_reflection_sql('c.name')} AS [name],
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
            LEFT OUTER JOIN #{database}.sys.index_columns ic
              ON k.parent_object_id = ic.object_id
              AND k.unique_index_id = ic.index_id
              AND c.column_id = ic.column_id
            WHERE
              o.name = #{object_name}
              AND s.name = #{schema_name}
            ORDER BY
              c.column_id
          }.gsub(/[ \t\r\n]+/, " ").strip
        end

        def remove_check_constraints(table_name, column_name)
          constraints = select_values "SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = '#{quote_string(table_name)}' and COLUMN_NAME = '#{quote_string(column_name)}'", "SCHEMA"
          constraints.each do |constraint|
            do_execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{quote_column_name(constraint)}"
          end
        end

        def remove_default_constraint(table_name, column_name)
          # If their are foreign keys in this table, we could still get back a 2D array, so flatten just in case.
          execute_procedure(:sp_helpconstraint, table_name, "nomsg").flatten.select do |row|
            row["constraint_type"] == "DEFAULT on column #{column_name}"
          end.each do |row|
            do_execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{row['constraint_name']}"
          end
        end

        def remove_indexes(table_name, column_name)
          indexes(table_name).select { |index| index.columns.include?(column_name.to_s) }.each do |index|
            remove_index(table_name, name: index.name)
          end
        end

        # === SQLServer Specific (Misc Helpers) ========================= #

        def get_table_name(sql)
          tn = if sql =~ /^\s*(INSERT|EXEC sp_executesql N'INSERT)(\s+INTO)?\s+([^\(\s]+)\s*|^\s*update\s+([^\(\s]+)\s*/i
                 Regexp.last_match[3] || Regexp.last_match[4]
               elsif sql =~ /FROM\s+([^\(\s]+)\s*/i
                 Regexp.last_match[1]
               else
                 nil
               end
          SQLServer::Utils.extract_identifiers(tn).object
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
          view_info ? get_table_name(view_info["VIEW_DEFINITION"]) : table_name
        end

        def view_information(table_name)
          @view_information ||= {}
          @view_information[table_name] ||= begin
            identifier = SQLServer::Utils.extract_identifiers(table_name)
            view_info = select_one "SELECT * FROM INFORMATION_SCHEMA.VIEWS WITH (NOLOCK) WHERE TABLE_NAME = #{quote(identifier.object)}", "SCHEMA"
            if view_info
              view_info = view_info.with_indifferent_access
              if view_info[:VIEW_DEFINITION].blank? || view_info[:VIEW_DEFINITION].length == 4000
                view_info[:VIEW_DEFINITION] = begin
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
          view_definition = view_information(table_name)[:VIEW_DEFINITION]
          return column_name unless view_definition

          match_data = view_definition.match(/([\w-]*)\s+as\s+#{column_name}/im)
          match_data ? match_data[1] : column_name
        end

        def create_table_definition(*args, **options)
          SQLServer::TableDefinition.new(self, *args, **options)
        end
      end
    end
  end
end
