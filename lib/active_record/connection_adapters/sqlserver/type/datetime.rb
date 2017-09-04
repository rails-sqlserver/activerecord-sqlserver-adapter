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
            time_method = default_timezone == :local ? :utc : :time
            fast_string_to_time_zone.strptime(string, fast_string_to_time_format).send(time_method)
          rescue ArgumentError
            super
          end

          def fast_string_to_time_format
            "#{::Time::DATE_FORMATS[:_sqlserver_datetime]}.%N".freeze
          end

          def fast_string_to_time_zone
            ::Time.zone || ActiveSupport::TimeZone['UTC']
          end

        end
      end
    end
  end
end
