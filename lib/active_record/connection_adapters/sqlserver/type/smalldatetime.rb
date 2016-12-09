module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class SmallDateTime < DateTime

          def type
            :smalldatetime
          end

          def sqlserver_type
            'smalldatetime'.freeze
          end

          private

          def apply_seconds_precision(value)
            value.change usec: 0
          end

        end
      end
    end
  end
end
