# frozen_string_literal: true

require "active_record/relation"
require "active_record/version"

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Calculations
          alias_method :_original_non_sqlserver_calculate, :calculate

          # Same as original except we don't perform PostgreSQL hack that removes ordering.
          def calculate(operation, column_name)
            return _original_non_sqlserver_calculate unless connection.sqlserver?

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

          alias_method :_original_non_sqlserver_build_count_subquery, :build_count_subquery

          def build_count_subquery(relation, column_name, distinct)
            return _original_non_sqlserver_build_count_subquery unless connection.sqlserver?

            super(relation.unscope(:order), column_name, distinct)
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
