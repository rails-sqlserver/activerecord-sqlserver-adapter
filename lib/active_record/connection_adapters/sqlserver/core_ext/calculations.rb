require 'active_record/relation'
require 'active_record/version'

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Calculations
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
