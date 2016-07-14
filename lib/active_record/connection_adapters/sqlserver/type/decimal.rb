module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Decimal < ActiveRecord::Type::Decimal

          def sqlserver_type
            'decimal'.tap do |type|
              type << "(#{precision.to_i},#{scale.to_i})" if precision || scale
            end
          end

        end
      end
    end
  end
end
