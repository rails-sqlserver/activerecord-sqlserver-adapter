require 'active_record/relation'
require 'active_record/version'

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module FinderMethods

          private

          # Same as original except we order by values in distinct select if present.
          def construct_relation_for_exists(conditions)
            if distinct_value && offset_value
              relation = limit!(1)

              if select_values.present?
                relation = relation.order(*select_values)
              else
                relation = relation.except(:order)
              end
            else
              relation = except(:select, :distinct, :order)._select!(::ActiveRecord::FinderMethods::ONE_AS_ONE).limit!(1)
            end

            case conditions
            when Array, Hash
              relation.where!(conditions) unless conditions.empty?
            else
              relation.where!(primary_key => conditions) unless conditions == :none
            end

            relation
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.include(ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::FinderMethods)
end
