module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Time < ActiveRecord::Type::Time

          include TimeValueFractional2

          def type_cast_for_database(value)
            return super unless value.acts_like?(:time)
            time = value.to_s(:_sqlserver_time)
            "#{time}".tap do |v|
              fraction = quote_fractional(value)
              v << ".#{fraction}" unless fraction.to_i.zero?
            end
          end

          def type_cast_for_schema(value)
            type_cast_for_database(value).inspect
          end


          private

          def cast_value(value)
            value = value.acts_like?(:time) ? value : super
            return if value.blank?
            value = value.change year: 2000, month: 01, day: 01
            cast_fractional(value)
          end

          def fractional_scale
            precision
          end

        end
      end
    end
  end
end
