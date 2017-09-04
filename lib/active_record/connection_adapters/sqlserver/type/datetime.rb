module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class DateTime < ActiveRecord::Type::DateTime

          include TimeValueFractional

          def sqlserver_type
            'datetime'.freeze
          end

          def serialize(value)
            value = super
            return value unless value.acts_like?(:time)
            datetime = value.to_s(:_sqlserver_datetime).tap do |v|
              fraction = quote_fractional(value)
              v << ".#{fraction}"
            end
            Data.new datetime, self
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

          def fast_string_to_time(string)
            time = ActiveSupport::TimeZone['UTC'].strptime(string, fast_string_to_time_format)
            new_time(time.year, time.month, time.day, time.hour,
                     time.min, time.sec, Rational(time.nsec, 1_000))
          rescue ArgumentError
            super
          end

          def fast_string_to_time_format
            "#{::Time::DATE_FORMATS[:_sqlserver_datetime]}.%N".freeze
          end
        end
      end
    end
  end
end
