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

          def cast_value(value)
            super.try(:in_time_zone)
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

          # Copy of module ActiveModel::Type::Helpers::TimeValue with
          # else condition using a zone for local parsing.
          def new_time(year, mon, mday, hour, min, sec, microsec, offset = nil)
            return if year.nil? || (year == 0 && mon == 0 && mday == 0)
            if offset
              time = ::Time.utc(year, mon, mday, hour, min, sec, microsec) rescue nil
              return unless time
              time -= offset
              is_utc? ? time : time.getlocal
            else
              fast_string_to_time_zone.local(year, mon, mday, hour, min, sec, microsec) rescue nil
            end
          end

        end
      end
    end
  end
end
