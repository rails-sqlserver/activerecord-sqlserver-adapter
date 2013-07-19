module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module SchemaStatements
        
        def native_database_types
          @native_database_types ||= initialize_native_database_types.freeze
        end

        # Drop the database 
        def drop_database(name)
          execute "IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = #{quote(name)}) DROP DATABASE #{quote_table_name(name)}"
        end

        def tables(table_type = 'BASE TABLE')
          select_values "SELECT #{lowercase_schema_reflection_sql('TABLE_NAME')} FROM INFORMATION_SCHEMA.TABLES #{"WHERE TABLE_TYPE = '#{table_type}'" if table_type} ORDER BY TABLE_NAME", 'SCHEMA'
        end

        def table_exists?(table_name)
          return false if table_name.blank?
          unquoted_table_name = Utils.unqualify_table_name(table_name)
          super || tables.include?(unquoted_table_name) || views.include?(unquoted_table_name)
        end

        def indexes(table_name, name = nil)
          data = select("EXEC sp_helpindex #{quote(table_name)}",name) rescue []
          data.inject([]) do |indexes,index|
            index = index.with_indifferent_access
            if index[:index_description] =~ /primary key/
              indexes
            else
              name    = index[:index_name]
              unique  = index[:index_description] =~ /unique/
              columns = index[:index_keys].split(',').map do |column|
                column.strip!
                column.gsub! '(-)', '' if column.ends_with?('(-)')
                column
              end
              indexes << IndexDefinition.new(table_name, name, unique, columns)
            end
          end
        end

        def columns(table_name, name = nil)
          return [] if table_name.blank?
          column_definitions(table_name).collect do |ci|
            sqlserver_options = ci.except(:name,:default_value,:type,:null).merge(:database_year=>database_year)
            SQLServerColumn.new ci[:name], ci[:default_value], ci[:type], ci[:null], sqlserver_options
          end
        end
        
        def rename_table(table_name, new_name)
          do_execute "EXEC sp_rename '#{table_name}', '#{new_name}'"
        end
        
        def remove_column(table_name, column_name, type, options = {})
          raise ArgumentError.new("You must specify a column name.  Example: remove_column(:people, :first_name)") if column_name.blank?
          remove_check_constraints(table_name, column_name)
          remove_default_constraint(table_name, column_name)
          remove_indexes(table_name, column_name)
          do_execute "ALTER TABLE #{quote_table_name(table_name)} DROP COLUMN #{quote_column_name(column_name)}"
        end

        def remove_columns(table_name, *column_names)
          raise ArgumentError.new("You must specify at least one column name.  Example: remove_column(:people, :first_name)") if column_names.empty?
          ActiveSupport::Deprecation.warn 'Passing array to remove_columns is deprecated, please use multiple arguments, like: `remove_columns(:posts, :foo, :bar)`', caller if column_names.flatten!
          column_names.flatten.each do |column_name|
            remove_check_constraints(table_name, column_name)
            remove_default_constraint(table_name, column_name)
            remove_indexes(table_name, column_name)
            do_execute "ALTER TABLE #{quote_table_name(table_name)} DROP COLUMN #{quote_column_name(column_name)}"
          end
        end

        def change_column(table_name, column_name, type, options = {})
          sql_commands = []
          column_object = schema_cache.columns[table_name].detect { |c| c.name.to_s == column_name.to_s }
          change_column_sql = "ALTER TABLE #{quote_table_name(table_name)} ALTER COLUMN #{quote_column_name(column_name)} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
          change_column_sql << " NOT NULL" if options[:null] == false
          sql_commands << change_column_sql
          if options_include_default?(options) || (column_object && column_object.type != type.to_sym)
           	remove_default_constraint(table_name,column_name)
          end
          if options_include_default?(options)
            sql_commands << "ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{default_constraint_name(table_name,column_name)} DEFAULT #{quote(options[:default])} FOR #{quote_column_name(column_name)}"
          end
          sql_commands.each { |c| do_execute(c) }
        end

        def change_column_default(table_name, column_name, default)
          remove_default_constraint(table_name, column_name)
          do_execute "ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{default_constraint_name(table_name, column_name)} DEFAULT #{quote(default)} FOR #{quote_column_name(column_name)}"
        end

        def rename_column(table_name, column_name, new_column_name)
          detect_column_for! table_name, column_name
          do_execute "EXEC sp_rename '#{table_name}.#{column_name}', '#{new_column_name}', 'COLUMN'"
        end
        
        def remove_index!(table_name, index_name)
          do_execute "DROP INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)}"
        end

        def type_to_sql(type, limit = nil, precision = nil, scale = nil)
          type_limitable = ['string','integer','float','char','nchar','varchar','nvarchar'].include?(type.to_s)
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

        def change_column_null(table_name, column_name, null, default = nil)
          column = detect_column_for! table_name, column_name
          unless null || default.nil?
            do_execute("UPDATE #{quote_table_name(table_name)} SET #{quote_column_name(column_name)}=#{quote(default)} WHERE #{quote_column_name(column_name)} IS NULL")
          end
          sql = "ALTER TABLE #{table_name} ALTER COLUMN #{quote_column_name(column_name)} #{type_to_sql column.type, column.limit, column.precision, column.scale}"
          sql << " NOT NULL" unless null
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
            :primary_key  => "int NOT NULL IDENTITY(1,1) PRIMARY KEY",
            :string       => { :name => native_string_database_type, :limit => 255  },
            :text         => { :name => native_text_database_type },
            :integer      => { :name => "int", :limit => 4 },
            :float        => { :name => "float", :limit => 8 },
            :decimal      => { :name => "decimal" },
            :datetime     => { :name => "datetime" },
            :timestamp    => { :name => "datetime" },
            :time         => { :name => native_time_database_type },
            :date         => { :name => native_date_database_type },
            :binary       => { :name => native_binary_database_type },
            :boolean      => { :name => "bit"},
            # These are custom types that may move somewhere else for good schema_dumper.rb hacking to output them.
            :char         => { :name => 'char' },
            :varchar_max  => { :name => 'varchar(max)' },
            :nchar        => { :name => "nchar" },
            :nvarchar     => { :name => "nvarchar", :limit => 255 },
            :nvarchar_max => { :name => "nvarchar(max)" },
            :ntext        => { :name => "ntext" },
            :ss_timestamp => { :name => 'timestamp' }
          }
        end

        def column_definitions(table_name)
          db_name = Utils.unqualify_db_name(table_name)
          db_name_with_period = "#{db_name}." if db_name
          table_schema = Utils.unqualify_table_schema(table_name)
          table_name = Utils.unqualify_table_name(table_name)
          sql = %{
            SELECT DISTINCT 
            #{lowercase_schema_reflection_sql('columns.TABLE_NAME')} AS table_name,
            #{lowercase_schema_reflection_sql('columns.COLUMN_NAME')} AS name,
            columns.DATA_TYPE AS type,
            columns.COLUMN_DEFAULT AS default_value,
            columns.NUMERIC_SCALE AS numeric_scale,
            columns.NUMERIC_PRECISION AS numeric_precision,
            columns.ordinal_position,
            CASE
              WHEN columns.DATA_TYPE IN ('nchar','nvarchar') THEN columns.CHARACTER_MAXIMUM_LENGTH
              ELSE COL_LENGTH('#{db_name_with_period}'+columns.TABLE_SCHEMA+'.'+columns.TABLE_NAME, columns.COLUMN_NAME)
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
            FROM #{db_name_with_period}INFORMATION_SCHEMA.COLUMNS columns
            LEFT OUTER JOIN #{db_name_with_period}INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
              ON TC.TABLE_NAME = columns.TABLE_NAME
              AND TC.CONSTRAINT_TYPE = N'PRIMARY KEY'
            LEFT OUTER JOIN #{db_name_with_period}INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KCU
              ON KCU.COLUMN_NAME = columns.COLUMN_NAME
              AND KCU.CONSTRAINT_NAME = TC.CONSTRAINT_NAME
              AND KCU.CONSTRAINT_CATALOG = TC.CONSTRAINT_CATALOG
              AND KCU.CONSTRAINT_SCHEMA = TC.CONSTRAINT_SCHEMA
            INNER JOIN #{db_name}.sys.schemas AS s
              ON s.name = columns.TABLE_SCHEMA
              AND s.schema_id = s.schema_id
            INNER JOIN #{db_name}.sys.objects AS o
              ON s.schema_id = o.schema_id
              AND o.is_ms_shipped = 0
              AND o.type IN ('U', 'V')
              AND o.name = columns.TABLE_NAME
            INNER JOIN #{db_name}.sys.columns AS c
              ON o.object_id = c.object_id
              AND c.name = columns.COLUMN_NAME
            WHERE columns.TABLE_NAME = @0
              AND columns.TABLE_SCHEMA = #{table_schema.blank? ? "schema_name()" : "@1"}
            ORDER BY columns.ordinal_position
          }.gsub(/[ \t\r\n]+/,' ')
          binds = [['table_name', table_name]]
          binds << ['table_schema',table_schema] unless table_schema.blank?
          results = do_exec_query(sql, 'SCHEMA', binds)
          results.collect do |ci|
            ci = ci.symbolize_keys
            ci[:type] = case ci[:type]
                         when /^bit|image|text|ntext|datetime$/
                           ci[:type]
                         when /^numeric|decimal$/i
                           "#{ci[:type]}(#{ci[:numeric_precision]},#{ci[:numeric_scale]})"
                         when /^float|real$/i
                           "#{ci[:type]}(#{ci[:numeric_precision]})"
                         when /^char|nchar|varchar|nvarchar|varbinary|bigint|int|smallint$/
                           ci[:length].to_i == -1 ? "#{ci[:type]}(max)" : "#{ci[:type]}(#{ci[:length]})"
                         else
                           ci[:type]
                         end
            if ci[:default_value].nil? && schema_cache.view_names.include?(table_name)
              real_table_name = table_name_or_views_table_name(table_name)
              real_column_name = views_real_column_name(table_name,ci[:name])
              col_default_sql = "SELECT c.COLUMN_DEFAULT FROM #{db_name_with_period}INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = '#{real_table_name}' AND c.COLUMN_NAME = '#{real_column_name}'"
              ci[:default_value] = select_value col_default_sql, 'SCHEMA'
            end
            ci[:default_value] = case ci[:default_value]
                                 when nil, '(null)', '(NULL)'
                                   nil
                                 when /\A\((\w+\(\))\)\Z/
                                   ci[:default_function] = $1
                                   nil
                                 else
                                   match_data = ci[:default_value].match(/\A\(+N?'?(.*?)'?\)+\Z/m)
                                   match_data ? match_data[1] : nil
                                 end
            ci[:null] = ci[:is_nullable].to_i == 1 ; ci.delete(:is_nullable)
            ci[:is_primary] = ci[:is_primary].to_i == 1
            ci[:is_identity] = ci[:is_identity].to_i == 1 unless [TrueClass, FalseClass].include?(ci[:is_identity].class)
            ci
          end
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
          indexes(table_name).select{ |index| index.columns.include?(column_name.to_s) }.each do |index|
            remove_index(table_name, {:name => index.name})
          end
        end
        
        # === SQLServer Specific (Misc Helpers) ========================= #
        
        def get_table_name(sql)
          if sql =~ /^\s*(INSERT|EXEC sp_executesql N'INSERT)\s+INTO\s+([^\(\s]+)\s*|^\s*update\s+([^\(\s]+)\s*/i
            $2 || $3
          elsif sql =~ /FROM\s+([^\(\s]+)\s*/i
            $1
          else
            nil
          end
        end
        
        def default_constraint_name(table_name, column_name)
          "DF_#{table_name}_#{column_name}"
        end
        
        def detect_column_for!(table_name, column_name)
          unless column = schema_cache.columns[table_name].detect { |c| c.name == column_name.to_s }
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
          table_name = Utils.unqualify_table_name(table_name)
          view_info = select_one "SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = '#{table_name}'", 'SCHEMA'
          if view_info
            view_info = view_info.with_indifferent_access
            if view_info[:VIEW_DEFINITION].blank? || view_info[:VIEW_DEFINITION].length == 4000
              view_info[:VIEW_DEFINITION] = begin
                                              select_values("EXEC sp_helptext #{quote_table_name(table_name)}", 'SCHEMA').join
                                            rescue
                                              warn "No view definition found, possible permissions problem.\nPlease run GRANT VIEW DEFINITION TO your_user;"
                                              nil
                                            end
            end
          end
          view_info
        end
        
        def table_name_or_views_table_name(table_name)
          unquoted_table_name = Utils.unqualify_table_name(table_name)
          schema_cache.view_names.include?(unquoted_table_name) ? view_table_name(unquoted_table_name) : unquoted_table_name
        end
        
        def views_real_column_name(table_name,column_name)
          view_definition = schema_cache.view_information(table_name)[:VIEW_DEFINITION]
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
        
        def with_identity_insert_enabled(table_name)
          table_name = quote_table_name(table_name_or_views_table_name(table_name))
          set_identity_insert(table_name, true)
          yield
        ensure
          set_identity_insert(table_name, false)
        end

        def set_identity_insert(table_name, enable = true)
          sql = "SET IDENTITY_INSERT #{table_name} #{enable ? 'ON' : 'OFF'}"
          do_execute sql, 'SCHEMA'
        rescue Exception => e
          raise ActiveRecordError, "IDENTITY_INSERT could not be turned #{enable ? 'ON' : 'OFF'} for table #{table_name}"
        end

        def identity_column(table_name)
          table = Utils.unqualify_table_name table_name
          schema_cache.columns(table).detect(&:is_identity?)
        end

      end
    end
  end
end
