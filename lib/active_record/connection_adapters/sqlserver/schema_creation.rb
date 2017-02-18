module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class SchemaCreation < AbstractAdapter::SchemaCreation

        private

        def visit_TableDefinition(o)
          table_name = o.name
          table_name = "##{table_name}" if o.temporary
          table_name = quote_table_name(table_name)
          if o.as
            projections, source = @conn.to_sql(o.as).match(%r{SELECT\s+(.*)?\s+FROM\s+(.*)?}).captures
            select_into = "SELECT #{projections} INTO #{table_name} FROM #{source}"
          else
            create_sql = "CREATE TABLE "
            create_sql << "#{table_name} "
            create_sql << "(#{o.columns.map { |c| accept c }.join(', ')}) "
            create_sql << "#{o.options}"
            create_sql
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
