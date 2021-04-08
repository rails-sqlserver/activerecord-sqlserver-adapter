# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class DecimalWithoutScale < ActiveRecord::Type::DecimalWithoutScale
          def sqlserver_type
            "decimal".yield_self do |type|
              type += "(#{precision.to_i},0)" if precision
              type
            end
          end

          def type_cast_for_schema(value)
            value.is_a?(BigDecimal) ? value.to_s : value.inspect
          end
        end
      end
    end
  end
end
