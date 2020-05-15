# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class DateTimeOffset < DateTime2
          def type
            :datetimeoffset
          end

          def sqlserver_type
            "datetimeoffset(#{precision.to_i})"
          end

          def quoted(value)
            Utils.quote_string_single(value)
          end
        end
      end
    end
  end
end
