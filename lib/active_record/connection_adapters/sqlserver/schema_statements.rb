module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module SchemaStatements

        def native_database_types
          @native_database_types ||= initialize_native_database_types.freeze
        end

        def data_sources
          tables + views
        end

        def tables(table_type = 'BASE TABLE')
          select_values "SELECT #{lowercase_schema_reflection_sql('TABLE_NAME')} FROM INFORMATION_SCHEMA.TABLES #{"WHERE TABLE_TYPE = '#{table_type}'" if table_type} ORDER BY TABLE_NAME", 'SCHEMA'
        end

        def table_exists?(table_name)
          return false if table_name.blank?
          unquoted_table_name = SQLServer::Utils.extract_identifiers(table_name).object
          super || tables.include?(unquoted_table_name) || views.include?(unquoted_table_name)
        end

        def create_table(table_name, options = {})
          res = super
          schema_cache.clear_table_cache!(table_name)
          res
        end

        def indexes(table_name, name = nil)
          data = select("EXEC sp_helpindex #{quote(table_name)}", name) rescue []
          data.reduce([]) do |indexes, index|
            index = index.with_indifferent_access
            if index[:index_description] =~ /primary key/
              indexes
            else
              name    = index[:index_name]
              unique  = index[:index_description] =~ /unique/
              where   = select_value("SELECT [filter_definition] FROM sys.indexes WHERE name = #{quote(name)}")
              columns = index[:index_keys].split(',').map do |column|
                column.strip!
                column.gsub! '(-)', '' if column.ends_with?('(-)')
                column
              end
              indexes << IndexDefinition.new(table_name, name, unique, columns, nil, nil, where)
            end
          end
        end

        def columns(table_name, _name = nil)
          return [] if table_name.blank?
          column_definitions(table_name).map do |ci|
            sqlserver_options = ci.slice :ordinal_position, :is_primary, :is_identity, :default_function, :table_name, :collation
            cast_type = lookup_cast_type(ci[:type])
            new_column ci[:name], ci[:default_value], cast_type, ci[:type], ci[:null], sqlserver_options
          end
        end

        def new_column(name, default, cast_type, sql_type = nil, null = true, sqlserver_options={})
          SQLServerColumn.new name, default, cast_type, sql_type, null, sqlserver_options
        end

        def rename_table(table_name, new_name)
          do_execute "EXEC sp_rename '#{table_name}', '#{new_name}'"
          rename_table_indexes(table_name, new_name)
        end

        def remove_column(table_name, column_name, type = nil, options = {})
          raise ArgumentError.new('You must specify at least one column name.  Example: remove_column(:people, :first_name)') if column_name.is_a? Array
          remove_check_constraints(table_name, column_name)
          remove_default_constraint(table_name, column_name)
          remove_indexes(table_name, column_name)
          do_execute "ALTER TABLE #{quote_table_name(table_name)} DROP COLUMN #{quote_column_name(column_name)}"
        end

        def change_column(table_name, column_name, type, options = {})
          sql_commands = []
          indexes = []
          column_object = schema_cache.columns(table_name).find { |c| c.name.to_s == column_name.to_s }
          if options_include_default?(options) || (column_object && column_object.type != type.to_sym)
            remove_default_constraint(table_name, column_name)
            indexes = indexes(table_name).select { |index| index.columns.include?(column_name.to_s) }
            remove_indexes(table_name, column_name)
          end
          sql_commands << "UPDATE #{quote_table_name(table_name)} SET #{quote_column_name(column_name)}=#{quote_default_value(options[:default], column_object)} WHERE #{quote_column_name(column_name)} IS NULL" if !options[:null].nil? && options[:null] == false && !options[:default].nil?
          sql_commands << "ALTER TABLE #{quote_table_name(table_name)} ALTER COLUMN #{quote_column_name(column_name)} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
          sql_commands[-1] << ' NOT NULL' if !options[:null].nil? && options[:null] == false
          if options_include_default?(options)
            sql_commands << "ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{default_constraint_name(table_name, column_name)} DEFAULT #{quote_default_value(options[:default], column_object)} FOR #{quote_column_name(column_name)}"
          end
          # Add any removed indexes back
          indexes.each do |index|
            sql_commands << "CREATE INDEX #{quote_table_name(index.name)} ON #{quote_table_name(table_name)} (#{index.columns.map { |c| quote_column_name(c) }.join(', ')})"
          end
          sql_commands.each { |c| do_execute(c) }
        end

        def change_column_default(table_name, column_name, default)
          schema_cache.clear_table_cache!(table_name)
          remove_default_constraint(table_name, column_name)
          column_object = schema_cache.columns(table_name).find { |c| c.name.to_s == column_name.to_s }
          do_execute "ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{default_constraint_name(table_name, column_name)} DEFAULT #{quote_default_value(default, column_object)} FOR #{quote_column_name(column_name)}"
          schema_cache.clear_table_cache!(table_name)
        end

        def rename_column(table_name, column_name, new_column_name)
          schema_cache.clear_table_cache!(table_name)
          detect_column_for! table_name, column_name
          identifier = SQLServer::Utils.extract_identifiers("#{table_name}.#{column_name}")
          execute_procedure :sp_rename, identifier.quoted, new_column_name, 'COLUMN'
          rename_column_indexes(table_name, column_name, new_column_name)
          schema_cache.clear_table_cache!(table_name)
        end

        def rename_index(table_name, old_name, new_name)
          raise ArgumentError, "Index name '#{new_name}' on table '#{table_name}' is too long; the limit is #{allowed_index_name_length} characters" if new_name.length > allowed_index_name_length
          identifier = SQLServer::Utils.extract_identifiers("#{table_name}.#{old_name}")
          execute_procedure :sp_rename, identifier.quoted, new_name, 'INDEX'
        end

        def remove_index!(table_name, index_name)
          do_execute "DROP INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)}"
        end

        def foreign_keys(table_name)
          identifier = SQLServer::Utils.extract_identifiers(table_name)
          fk_info = execute_procedure :sp_fkeys, nil, identifier.schema, nil, identifier.object, identifier.schema
          fk_info.map do |row|
            from_table = identifier.object
            to_table = row['PKTABLE_NAME']
            options = {
              name: row['FK_NAME'],
              column: row['FKCOLUMN_NAME'],
              primary_key: row['PKCOLUMN_NAME'],
              on_update: extract_foreign_key_action('update', row['FK_NAME']),
              on_delete: extract_foreign_key_action('delete', row['FK_NAME'])
            }
            ForeignKeyDefinition.new from_table, to_table, options
          end
        end

        def extract_foreign_key_action(action, fk_name)
          case select_value("SELECT #{action}_referential_action_desc FROM sys.foreign_keys WHERE name = '#{fk_name}'")
          when 'CASCADE' then :cascade
          when 'SET_NULL' then :nullify
          end
        end

        def type_to_sql(type, limit = nil, precision = nil, scale = nil)
          type_limitable = %w(string integer float char nchar varchar nvarchar).include?(type.to_s)
          limit = nil unless type_limitable
          case type.to_s
          when 'integer'
            case limit
            when 1..2       then  'smallint'
            when 3..4, nil  then  'integer'
            when 5..8       then  'bigint'
            else raise(ActiveRecordError, "No integer type has byte size #{limit}. Use a numeric with precision 0 instead.")
            end
          else
            super
          end
        end

        def columns_for_distinct(columns, orders)
          order_columns = orders.reject(&:blank?).map{ |s|
              s = s.to_sql unless s.is_a?(String)
              s.gsub(/\s+(?:ASC|DESC)\b/i, '')
               .gsub(/\s+NULLS\s+(?:FIRST|LAST)\b/i, '')
            }.reject(&:blank?).map.with_index { |column, i| "#{column} AS alias_#{i}" }
          [super, *order_columns].join(', ')
        end

        def change_column_null(table_name, column_name, allow_null, default = nil)
          table_id = SQLServer::Utils.extract_identifiers(table_name)
          column_id = SQLServer::Utils.extract_identifiers(column_name)
          column = detect_column_for! table_name, column_name
          if !allow_null.nil? && allow_null == false && !default.nil?
            do_execute("UPDATE #{table_id} SET #{column_id}=#{quote(default)} WHERE #{column_id} IS NULL")
          end
          sql = "ALTER TABLE #{table_id} ALTER COLUMN #{column_id} #{type_to_sql column.type, column.limit, column.precision, column.scale}"
          sql << ' NOT NULL' if !allow_null.nil? && allow_null == false
          do_execute sql
        end

        # === SQLServer Specific ======================================== #

        def views
          tables('VIEW')
        end


        protected

        # === SQLServer Specific ======================================== #

        def initialize_native_database_types
          {
            primary_key: 'int NOT NULL IDENTITY(1,1) PRIMARY KEY',
            integer: { name: 'int', limit: 4 },
            bigint: { name: 'bigint' },
            boolean: { name: 'bit' },
            decimal: { name: 'decimal' },
            money: { name: 'money' },
            smallmoney: { name: 'smallmoney' },
            float: { name: 'float' },
            real: { name: 'real' },
            date: { name: 'date' },
            datetime: { name: 'datetime' },
            datetime2: { name: 'datetime2' },
            datetimeoffset: { name: 'datetimeoffset' },
            smalldatetime: { name: 'smalldatetime' },
            timestamp: { name: 'datetime' },
            time: { name: 'time' },
            char: { name: 'char' },
            varchar: { name: 'varchar', limit: 8000 },
            varchar_max: { name: 'varchar(max)' },
            text_basic: { name: 'text' },
            nchar: { name: 'nchar' },
            string: { name: 'nvarchar', limit: 4000 },
            text: { name: 'nvarchar(max)' },
            ntext: { name: 'ntext' },
            binary_basic: { name: 'binary' },
            varbinary: { name: 'varbinary', limit: 8000 },
            binary: { name: 'varbinary(max)' },
            uuid: { name: 'uniqueidentifier' },
            ss_timestamp: { name: 'timestamp' }
          }
        end

        def column_definitions(table_name)
          identifier = if database_prefix_remote_server?
            SQLServer::Utils.extract_identifiers("#{database_prefix}#{table_name}")
          else
            SQLServer::Utils.extract_identifiers(table_name)
          end
          database    = identifier.fully_qualified_database_quoted
          view_exists = schema_cache.view_exists?(table_name)
          view_tblnm  = table_name_or_views_table_name(table_name) if view_exists
          sql = %{
            SELECT DISTINCT
            #{lowercase_schema_reflection_sql('columns.TABLE_NAME')} AS table_name,
            #{lowercase_schema_reflection_sql('columns.COLUMN_NAME')} AS name,
            columns.DATA_TYPE AS type,
            columns.COLUMN_DEFAULT AS default_value,
            columns.NUMERIC_SCALE AS numeric_scale,
            columns.NUMERIC_PRECISION AS numeric_precision,
            columns.DATETIME_PRECISION AS datetime_precision,
            columns.COLLATION_NAME AS collation,
            columns.ordinal_position,
            CASE
              WHEN columns.DATA_TYPE IN ('nchar','nvarchar','char','varchar') THEN columns.CHARACTER_MAXIMUM_LENGTH
              ELSE COL_LENGTH('#{database}.'+columns.TABLE_SCHEMA+'.'+columns.TABLE_NAME, columns.COLUMN_NAME)
            END AS [length],
            CASE
              WHEN columns.IS_NULLABLE = 'YES' THEN 1
              ELSE NULL
            END AS [is_nullable],
            CASE
              WHEN KCU.COLUMN_NAME IS NOT NULL AND TC.CONSTRAINT_TYPE = N'PRIMARY KEY' THEN 1
              ELSE NULL
            END AS [is_primary],
            c.is_identity AS [is_identity]
            FROM #{database}.INFORMATION_SCHEMA.COLUMNS columns
            LEFT OUTER JOIN #{database}.INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
              ON TC.TABLE_NAME = columns.TABLE_NAME
              AND TC.CONSTRAINT_TYPE = N'PRIMARY KEY'
            LEFT OUTER JOIN #{database}.INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU
              ON KCU.COLUMN_NAME = columns.COLUMN_NAME
              AND KCU.CONSTRAINT_NAME = TC.CONSTRAINT_NAME
              AND KCU.CONSTRAINT_CATALOG = TC.CONSTRAINT_CATALOG
              AND KCU.CONSTRAINT_SCHEMA = TC.CONSTRAINT_SCHEMA
            INNER JOIN #{database}.sys.schemas AS s
              ON s.name = columns.TABLE_SCHEMA
              AND s.schema_id = s.schema_id
            INNER JOIN #{database}.sys.objects AS o
              ON s.schema_id = o.schema_id
              AND o.is_ms_shipped = 0
              AND o.type IN ('U', 'V')
              AND o.name = columns.TABLE_NAME
            INNER JOIN #{database}.sys.columns AS c
              ON o.object_id = c.object_id
              AND c.name = columns.COLUMN_NAME
            WHERE columns.TABLE_NAME = @0
              AND columns.TABLE_SCHEMA = #{identifier.schema.blank? ? 'schema_name()' : '@1'}
            ORDER BY columns.ordinal_position
          }.gsub(/[ \t\r\n]+/, ' ')
          binds = [[info_schema_table_name_column, identifier.object]]
          binds << [info_schema_table_schema_column, identifier.schema] unless identifier.schema.blank?
          results = sp_executesql(sql, 'SCHEMA', binds)
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
                default = select_value "
                  SELECT c.COLUMN_DEFAULT
                  FROM #{database}.INFORMATION_SCHEMA.COLUMNS c
                  WHERE c.TABLE_NAME = '#{view_tblnm}'
                  AND c.COLUMN_NAME = '#{views_real_column_name(table_name, ci[:name])}'".squish, 'SCHEMA'
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
                value = select_value "SELECT CAST(#{value} AS #{type}) AS value", 'SCHEMA'
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

        def info_schema_table_name_column
          @info_schema_table_name_column ||= new_column 'table_name', nil, lookup_cast_type('nvarchar(128)'), 'nvarchar(128)', true
        end

        def info_schema_table_schema_column
          @info_schema_table_schema_column ||= new_column 'table_schema', nil, lookup_cast_type('nvarchar(128)'), 'nvarchar(128)', true
        end

        def remove_check_constraints(table_name, column_name)
          constraints = select_values "SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = '#{quote_string(table_name)}' and COLUMN_NAME = '#{quote_string(column_name)}'", 'SCHEMA'
          constraints.each do |constraint|
            do_execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{quote_column_name(constraint)}"
          end
        end

        def remove_default_constraint(table_name, column_name)
          # If their are foreign keys in this table, we could still get back a 2D array, so flatten just in case.
          execute_procedure(:sp_helpconstraint, table_name, 'nomsg').flatten.select do |row|
            row['constraint_type'] == "DEFAULT on column #{column_name}"
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

        def detect_column_for!(table_name, column_name)
          unless column = schema_cache.columns(table_name).find { |c| c.name == column_name.to_s }
            raise ActiveRecordError, "No such column: #{table_name}.#{column_name}"
          end
          column
        end

        def lowercase_schema_reflection_sql(node)
          lowercase_schema_reflection ? "LOWER(#{node})" : node
        end

        # === SQLServer Specific (View Reflection) ====================== #

        def view_table_name(table_name)
          view_info = schema_cache.view_information(table_name)
          view_info ? get_table_name(view_info['VIEW_DEFINITION']) : table_name
        end

        def view_information(table_name)
          identifier = SQLServer::Utils.extract_identifiers(table_name)
          view_info = select_one "SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = '#{identifier.object}'", 'SCHEMA'
          if view_info
            view_info = view_info.with_indifferent_access
            if view_info[:VIEW_DEFINITION].blank? || view_info[:VIEW_DEFINITION].length == 4000
              view_info[:VIEW_DEFINITION] = begin
                select_values("EXEC sp_helptext #{identifier.object_quoted}", 'SCHEMA').join
              rescue
                warn "No view definition found, possible permissions problem.\nPlease run GRANT VIEW DEFINITION TO your_user;"
                nil
              end
            end
          end
          view_info
        end

        def table_name_or_views_table_name(table_name)
          schema_cache.view_exists?(table_name) ? view_table_name(table_name) : table_name
        end

        def views_real_column_name(table_name, column_name)
          view_definition = schema_cache.view_information(table_name)[:VIEW_DEFINITION]
          return column_name unless view_definition
          match_data = view_definition.match(/([\w-]*)\s+as\s+#{column_name}/im)
          match_data ? match_data[1] : column_name
        end

        # === SQLServer Specific (Identity Inserts) ===================== #

        def query_requires_identity_insert?(sql)
          if insert_sql?(sql)
            table_name = get_table_name(sql)
            id_column = identity_column(table_name)
            id_column && sql =~ /^\s*(INSERT|EXEC sp_executesql N'INSERT)[^(]+\([^)]*\b(#{id_column.name})\b,?[^)]*\)/i ? quote_table_name(table_name) : false
          else
            false
          end
        end

        def insert_sql?(sql)
          !(sql =~ /^\s*(INSERT|EXEC sp_executesql N'INSERT)/i).nil?
        end

        def identity_column(table_name)
          schema_cache.columns(table_name).find(&:is_identity?)
        end


        private

        def create_table_definition(name, temporary, options, as = nil)
          SQLServer::TableDefinition.new native_database_types, name, temporary, options, as
        end

      end
    end
  end
end
