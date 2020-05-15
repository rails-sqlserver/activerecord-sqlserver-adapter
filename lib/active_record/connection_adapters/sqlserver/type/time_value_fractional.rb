# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        module TimeValueFractional
          private

          def apply_seconds_precision(value)
            return value if !value.respond_to?(fractional_property) || value.send(fractional_property).zero?

            value.change fractional_property => seconds_precision(value)
          end

          def seconds_precision(value)
            return 0 if fractional_scale == 0

            seconds = value.send(fractional_property).to_f / fractional_operator.to_f
            seconds = ((seconds * (1 / fractional_precision)).round / (1 / fractional_precision)).round(fractional_scale)
            (seconds * fractional_operator).round(0).to_i
          end

          def quote_fractional(value)
            return 0 if fractional_scale == 0

            frac_seconds = seconds_precision(value)
            seconds = (frac_seconds.to_f / fractional_operator.to_f).round(fractional_scale)
            seconds.to_d.to_s.split(".").last.to(fractional_scale - 1)
          end

          def fractional_property
            :usec
          end

          def fractional_digits
            6
          end

          def fractional_operator
            10**fractional_digits
          end

          def fractional_precision
            0.00333
          end

          def fractional_scale
            3
          end
        end

        module TimeValueFractional2
          include TimeValueFractional

          private

          def seconds_precision(value)
            seconds = super
            seconds > fractional_max ? fractional_scale_max : seconds
          end

          def fractional_property
            :nsec
          end

          def fractional_digits
            9
          end

          def fractional_precision
            0.0000001
          end

          def fractional_scale
            precision
          end

          def fractional_max
            999999999
          end

          def fractional_scale_max
            ("9" * fractional_scale) + ("0" * (fractional_digits - fractional_scale))
          end
        end
      end
    end
  end
end
