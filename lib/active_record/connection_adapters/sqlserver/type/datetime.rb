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
            return super unless value.acts_like?(:time)
            Data.new super, self
          end

          def deserialize(value)
            datetime = value.is_a?(Data) ? value.value : super
            return unless datetime
            zone_conversion(datetime)
          end

          def type_cast_for_schema(value)
            serialize(value).quoted
          end

          def quoted(value)
            datetime = value.to_s(:_sqlserver_datetime)
            datetime = "#{datetime}".tap do |v|
              fraction = quote_fractional(value)
              v << ".#{fraction}" unless fraction.to_i.zero?
            end
            Utils.quote_string_single(datetime)
          end

          class Data

            attr_reader :value, :type

            def initialize(value, type)
              @value, @type = value, type
            end

            def quoted
              type.quoted(@value)
            end

          end

          private

          def cast_value(value)
            value = value.acts_like?(:time) ? value : super
            return unless value
            apply_seconds_precision(value)
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
