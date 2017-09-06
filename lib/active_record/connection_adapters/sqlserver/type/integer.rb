module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Integer < ActiveRecord::Type::Integer

          RANGE = -2_147_483_648..2_147_483_647

          def sqlserver_type
            'int'.freeze
          end

          private

          def max_value
            2_147_483_647
          end

        end
      end
    end
  end
end
