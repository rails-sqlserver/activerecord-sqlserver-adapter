# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class SmallMoney < Money
          def initialize(**args)
            super
            @precision = 10
            @scale = 4
          end

          def type
            :smallmoney
          end

          def sqlserver_type
            "smallmoney"
          end
        end
      end
    end
  end
end
