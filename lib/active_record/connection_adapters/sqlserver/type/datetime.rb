module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class DateTime < ActiveRecord::Type::DateTime

          include Castable

          def type_cast_for_database(value)
            value = super(value)
            return unless value
            return value unless value =~ ConnectionAdapters::Column::Format::ISO_DATETIME
            "#{value.to_s(:db)}#{cast_usec_for_database(value)}"
          end


          private

          def cast_value(value)
            value = value.respond_to?(:usec) ? value : super
            return unless value
            value.change usec: cast_usec(value)
          end

          def cast_usec(value)
            return 0 if value.usec.zero?
            seconds = value.usec.to_f / 1_000_000.0
            ss_seconds = ((seconds * (1 / second_precision)).round / (1 / second_precision)).round(3)
            (ss_seconds * 1_000_000).to_i
          end

          def cast_usec_for_database(value)
            usec = cast_usec(value)
            '.' + (BigDecimal(usec.to_s) / 1_000_000).round(3).to_s.split('.').last
          end

          def second_precision
            0.00333
          end

        end
      end
    end
  end
end
