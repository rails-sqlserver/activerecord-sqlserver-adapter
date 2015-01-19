module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Money < Decimal

          def initialize(options = {})
            super
            @precision = 19
            @scale = 4
          end

          def type
            :money
          end

        end
      end
    end
  end
end
