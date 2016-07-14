module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class SmallDateTime < DateTime

          SQLSERVER_TYPE = 'smalldatetime'.freeze

          def type
            :smalldatetime
          end

          private

          def cast_fractional(value)
            value.change usec: 0
          end

        end
      end
    end
  end
end
