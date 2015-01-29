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
            table_name = quote_table_name(o.temporary ? "##{o.name}" : o.name)
            projections, source = @conn.to_sql(o.as).match(%r{SELECT\s+(.*)?\s+FROM\s+(.*)?}).captures
            select_into = "SELECT #{projections} INTO #{table_name} FROM #{source}"
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

        def action_sql(action, dependency)
          case dependency
          when :restrict
            raise ArgumentError, <<-MSG.strip_heredoc
              '#{dependency}' is not supported for :on_update or :on_delete.
              Supported values are: :nullify, :cascade
            MSG
          else
            super
          end
        end

      end
    end
  end
end
