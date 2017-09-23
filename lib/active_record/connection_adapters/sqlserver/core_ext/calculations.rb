require 'active_record/relation'
require 'active_record/version'

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Calculations
          private

          def build_count_subquery(relation, column_name, distinct)
            relation.select_values = [
              if column_name == :all
                distinct ? table[Arel.star] : Arel.sql(FinderMethods::ONE_AS_ONE)
              else
                column_alias = Arel.sql("count_column")
                aggregate_column(column_name).as(column_alias)
              end
            ]

            subquery = relation.arel.as(Arel.sql("subquery_for_count"))
            select_value = operation_over_aggregate_column(column_alias || Arel.star, "count", false)

            Arel::SelectManager.new(subquery).project(select_value)
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  if ActiveRecord::VERSION::MAJOR == 5 &&
     ActiveRecord::VERSION::MINOR == 1 &&
     ActiveRecord::VERSION::TINY >= 4
    mod = ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::Calculations
    ActiveRecord::Relation.prepend(mod)
  end
end
