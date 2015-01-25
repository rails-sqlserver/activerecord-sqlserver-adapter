module ActiveRecord
  module ConnectionAdapters
    module SQLServer
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

        def visit_TableDefinition(o)
          if o.as
            visitor = o.as.connection.visitor
            table_name = o.temporary ? "##{o.name}" : o.name
            select_into = "SELECT "
            select_into << "(#{visitor.accept(o.as.arel.projections, Arel::Collectors::PlainString.new).value}) "
            select_into << "INTO "
            select_into << "#{quote_table_name(table_name)} "
            select_into << "FROM "
            select_into << "#{visitor.accept(o.as.arel.froms[0], Arel::Collectors::PlainString.new).value}"
          else
            o.instance_variable_set :@as, nil
            super
          end
        end

        def add_column_options!(sql, options)
          column = options.fetch(:column) { return super }
          if (column.type == :uuid || column.type == :uniqueidentifier) && options[:default] =~ /\(\)/
            sql << " DEFAULT #{options.delete(:default)}"
          else
            super
          end
        end

      end
    end
  end
end
