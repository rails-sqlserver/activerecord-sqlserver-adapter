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
            super(relation.unscope(:order), column_name, distinct)
          end

          def type_cast_calculated_value(value, type, operation = nil)
            case operation
            when "count"   then value.to_i
            when "sum"     then type.deserialize(value || 0)
            when "average" then value&.respond_to?(:to_d) ? value.to_d : value
            else type.deserialize(value)
            end
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  mod = ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::Calculations
  ActiveRecord::Relation.prepend(mod)
end
