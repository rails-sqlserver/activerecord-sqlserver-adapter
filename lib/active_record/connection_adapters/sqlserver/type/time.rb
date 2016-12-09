module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Time < ActiveRecord::Type::Time

          include TimeValueFractional2

          def serialize(value)
            return super unless value.acts_like?(:time)
            time = value.to_s(:_sqlserver_time)
            "#{time}".tap do |v|
              fraction = quote_fractional(value)
              v << ".#{fraction}" unless fraction.to_i.zero?
            end
          end

          def type_cast_for_schema(value)
            serialize(value).inspect
          end

          def sqlserver_type
            "time(#{precision.to_i})"
          end


          private

          def cast_value(value)
            value = value.acts_like?(:time) ? value : super
            return if value.blank?
            value = value.change year: 2000, month: 01, day: 01
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
