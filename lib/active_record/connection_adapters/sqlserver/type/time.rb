Time::DATE_FORMATS[:_sqlserver_time] = '%H:%M:%S'

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Time < ActiveRecord::Type::Time

          def initialize(options = {})
            super
            @precision = nil if @precision == 7
          end

          # When FreeTDS/TinyTDS casts this data type natively.
          # include Castable

          def type_cast_for_database(value)
            return if value.nil?
            Quoter.new super, self
          end

          def type_cast_for_schema(value)
            value.acts_like?(:string) ? "'#{value}'" : super
          end

          def quote_ss(value)
            return unless value
            value = cast_value(value) if value.acts_like?(:string)
            date = value.to_s(:_sqlserver_time)
            frac = quote_usec(value)
            "'#{date}.#{frac}'"
          end


          private

          def cast_value(value)
            value = value.respond_to?(:usec) ? value.change(year: 2000, month: 01, day: 01) : super
            return if value.blank?
            value.change usec: cast_usec(value)
          end

          def cast_usec(value)
            (usec_to_seconds_frction(value) * 1_000_000).to_i
          end

          def usec_to_seconds_frction(value)
            (value.usec.to_f / 1_000_000.0).round(precision || 7)
          end

          def quote_usec(value)
            usec_to_seconds_frction(value).to_s.split('.').last
          end

        end
      end
    end
  end
end
