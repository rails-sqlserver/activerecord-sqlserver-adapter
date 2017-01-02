module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class DateTime < ActiveRecord::Type::DateTime

          include TimeValueFractional

          def initialize(*args)
            super
            @precision = nil if self.class == DateTime
          end

          def sqlserver_type
            'datetime'.freeze
          end

          def serialize(value)
            return super unless value.acts_like?(:time)
            datetime = super.to_s(:_sqlserver_datetime).tap do |v|
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

          def cast_value(value)
            value = value.acts_like?(:time) ? value : super
            return unless value
            apply_seconds_precision(value)
          end

          def fast_string_to_time(string)
            fast_string_to_time_zone.strptime(string, fast_string_to_time_format).time
          rescue ArgumentError
            super
          end

          def fast_string_to_time_format
            "#{::Time::DATE_FORMATS[:_sqlserver_datetime]}.%N".freeze
          end

          def fast_string_to_time_zone
            ::Time.zone || ActiveSupport::TimeZone.new('UTC')
          end

        end
      end
    end
  end
end
