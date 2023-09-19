# frozen_string_literal: true

require "active_record/relation"
require "active_record/version"

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Calculations
          def calculate(operation, column_name)
            if klass.connection.sqlserver?
              _calculate(operation, column_name)
            else
              super
            end
          end

          private

          # Same as original `calculate` method except we don't perform PostgreSQL hack that removes ordering.
          def _calculate(operation, column_name)
            operation = operation.to_s.downcase

            if @none
              case operation
              when "count", "sum"
                result = group_values.any? ? Hash.new : 0
                return @async ? Promise::Complete.new(result) : result
              when "average", "minimum", "maximum"
                result = group_values.any? ? Hash.new : nil
                return @async ? Promise::Complete.new(result) : result
              end
            end

            if has_include?(column_name)
              relation = apply_join_dependency

              if operation == "count"
                unless distinct_value || distinct_select?(column_name || select_for_count)
                  relation.distinct!
                  relation.select_values = [ klass.primary_key || table[Arel.star] ]
                end
                # PostgreSQL: ORDER BY expressions must appear in SELECT list when using DISTINCT
                # Start of monkey-patch
                # relation.order_values = [] if group_values.empty?
                # End of monkey-patch
              end

              relation.calculate(operation, column_name)
            else
              perform_calculation(operation, column_name)
            end
          end

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
