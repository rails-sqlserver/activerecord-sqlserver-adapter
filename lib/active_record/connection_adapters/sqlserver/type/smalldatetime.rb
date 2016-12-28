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

          def fast_string_to_time_format
            ::Time::DATE_FORMATS[:_sqlserver_datetime]
          end

          def apply_seconds_precision(value)
            value.change usec: 0
          end

        end
      end
    end
  end
end
