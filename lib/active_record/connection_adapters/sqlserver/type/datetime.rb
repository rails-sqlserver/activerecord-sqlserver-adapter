module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class DateTime < ActiveRecord::Type::DateTime

          include TimeValueFractional

          def type_cast_for_database(value)
            return super unless value.acts_like?(:time)
            value = zone_conversion(value)
            datetime = value.to_s(:_sqlserver_datetime)
            "#{datetime}".tap do |v|
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
            return unless value
            cast_fractional(value)
          end

          def zone_conversion(value)
            method = ActiveRecord::Base.default_timezone == :utc ? :getutc : :getlocal
            value.respond_to?(method) ? value.send(method) : value
          end

        end
      end
    end
  end
end
