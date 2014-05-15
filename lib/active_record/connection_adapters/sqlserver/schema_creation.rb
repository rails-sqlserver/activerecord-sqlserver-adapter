module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      class SchemaCreation < AbstractAdapter::SchemaCreation
        private

        def visit_ColumnDefinition(o)
          sql = super
          if o.primary_key? && o.type == :uuid
            sql << " PRIMARY KEY "
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
      end
    end
  end
end

