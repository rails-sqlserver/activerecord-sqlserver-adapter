module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      class SchemaCreation < AbstractAdapter::SchemaCreation
        private

        def visit_ColumnDefinition(o)
          sql = super
          if o.primary_key? && o.type == :uuid
            sql << ' PRIMARY KEY '
            add_column_options!(sql, column_options(o))
          end
          sql
        end

        def add_column_options!(sql, options)
          column = options.fetch(:column) { return super }
          if [:uniqueidentifier, :uuid].include?(column.type) && options[:default] =~ /\(\)/
            sql << " DEFAULT #{options.delete(:default)}"
            super
          else
            super
          end
        end

        def visit_TableDefinition(o)
          quoted_name = "#{quote_table_name((o.temporary ? '#' : '') + o.name.to_s)} "

          if o.as
            if o.as.is_a?(ActiveRecord::Relation)
              select = o.as.to_sql
            elsif o.as.is_a?(String)
              select = o.as
            else
              raise 'Only able to generate a table from a SELECT statement passed as a String or ActiveRecord::Relation'
            end

            create_sql = 'SELECT * INTO '
            create_sql << quoted_name
            create_sql << 'FROM ('
            create_sql << select
            create_sql << ') AS __sq'

          else
            create_sql = "CREATE TABLE "
            create_sql << quoted_name
            create_sql << "(#{o.columns.map { |c| accept c }.join(', ')}) "
            create_sql << "#{o.options}"
          end

          create_sql
        end
      end
    end
  end
end
