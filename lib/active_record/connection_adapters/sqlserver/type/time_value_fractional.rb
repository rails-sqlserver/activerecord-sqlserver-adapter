module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type

        module TimeValueFractional

          private

          def cast_fractional(value)
            return value if !value.respond_to?(fractional_property) || value.send(fractional_property).zero?
            frac_seconds = if fractional_scale == 0
                             0
                           else
                             seconds = value.send(fractional_property).to_f / fractional_operator.to_f
                             seconds = ((seconds * (1 / fractional_precision)).round / (1 / fractional_precision)).round(fractional_scale)
                             (seconds * fractional_operator).to_i
                           end
            value.change fractional_property => frac_seconds
          end

          def quote_fractional(value)
            seconds = (value.send(fractional_property).to_f / fractional_operator.to_f).round(fractional_scale)
            seconds.to_d.to_s.split('.').last.to(fractional_scale-1)
          end

          def fractional_property
            :usec
          end

          def fractional_digits
            6
          end

          def fractional_operator
            10 ** fractional_digits
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

        end

      end
    end
  end
end
