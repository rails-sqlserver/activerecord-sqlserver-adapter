# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Time < ActiveRecord::Type::Time
          include TimeValueFractional2

          def serialize(_value)
            value = super
            return value unless value.acts_like?(:time)

            time = "#{value.to_formatted_s(:_sqlserver_time)}.#{quote_fractional(value)}"
            Data.new(time, self)
          end

          def deserialize(value)
            value.is_a?(Data) ? super(value.value) : super
          end

          def type_cast_for_schema(value)
            serialize(value).quoted
          end

          def sqlserver_type
            "time(#{precision.to_i})"
          end

          def quoted(value)
            Utils.quote_string_single(value)
          end

          private

          def cast_value(_value)
            value = super
            return value unless value.is_a?(::Time)

            value = value.change(year: 2000, month: 0o1, day: 0o1)
            apply_seconds_precision(value)
          end

          def fractional_scale
            precision
          end
        end
      end
    end
  end
end
