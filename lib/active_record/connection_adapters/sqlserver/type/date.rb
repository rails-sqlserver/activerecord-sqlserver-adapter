# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Date < ActiveRecord::Type::Date
          def sqlserver_type
            "date"
          end

          def serialize(value)
            return unless value.present?

            date = super(value).to_s(:_sqlserver_dateformat)
            Data.new date, self
          end

          def deserialize(value)
            value.is_a?(Data) ? super(value.value) : super
          end

          def type_cast_for_schema(value)
            serialize(value).quoted
          end

          def quoted(value)
            Utils.quote_string_single(value)
          end

          private

          def fast_string_to_date(string)
            ::Date.strptime(string, fast_string_to_date_format)
          rescue ArgumentError
            super
          end

          def fast_string_to_date_format
            ::Date::DATE_FORMATS[:_sqlserver_dateformat]
          end
        end
      end
    end
  end
end
