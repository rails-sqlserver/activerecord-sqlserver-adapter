module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class SchemaCreation < AbstractAdapter::SchemaCreation

        private

        def visit_TableDefinition(o)
          if o.as
            table_name = quote_table_name(o.temporary ? "##{o.name}" : o.name)
            query = o.as.respond_to?(:to_sql) ? o.as.to_sql : o.as
            projections, source = query.match(%r{SELECT\s+(.*)?\s+FROM\s+(.*)?}).captures
            select_into = "SELECT #{projections} INTO #{table_name} FROM #{source}"
          else
            o.instance_variable_set :@as, nil
            super
          end
        end

        def add_column_options!(sql, options)
          sql << " DEFAULT #{quote_default_expression(options[:default], options[:column])}" if options_include_default?(options)
          if options[:null] == false
            sql << " NOT NULL"
          end
          if options[:is_identity] == true
            sql << " IDENTITY(1,1)"
          end
          if options[:primary_key] == true
            sql << " PRIMARY KEY"
          end
          sql
        end

        def action_sql(action, dependency)
          case dependency
          when :restrict
            raise ArgumentError, <<~MSG.squish
              '#{dependency}' is not supported for :on_update or :on_delete.
              Supported values are: :nullify, :cascade
            MSG
          else
            super
          end
        end

        def options_include_default?(options)
          super || options_primary_key_with_nil_default?(options)
        end

        def options_primary_key_with_nil_default?(options)
          options[:primary_key] && options.include?(:default) && options[:default].nil?
        end

      end
    end
  end
end
