# frozen_string_literal: true

require "active_record/relation"
require "active_record/version"

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Calculations
          # Same as original except we don't perform PostgreSQL hack that removes ordering.
          def calculate(operation, column_name)
            return super unless klass.connection.adapter_name == "SQLServer"

            if has_include?(column_name)
              relation = apply_join_dependency

              if operation.to_s.downcase == "count"
                unless distinct_value || distinct_select?(column_name || select_for_count)
                  relation.distinct!
                  relation.select_values = [klass.primary_key || table[Arel.star]]
                end
              end

              relation.calculate(operation, column_name)
            else
              perform_calculation(operation, column_name)
            end
          end

          private

          def build_count_subquery(relation, column_name, distinct)
            return super unless klass.connection.adapter_name == "SQLServer"

            super(relation.unscope(:order), column_name, distinct)
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  mod = ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::Calculations
  ActiveRecord::Relation.include(mod)
end
