module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class SmallMoney < Money

          def initialize(options = {})
            super
            @precision = 10
            @scale = 4
          end

          def type
            :smallmoney
          end

        end
      end
    end
  end
end
