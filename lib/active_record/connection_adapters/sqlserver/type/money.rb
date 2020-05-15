# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Money < Decimal
          def initialize(**args)
            super
            @precision = 19
            @scale = 4
          end

          def type
            :money
          end

          def sqlserver_type
            "money"
          end
        end
      end
    end
  end
end
