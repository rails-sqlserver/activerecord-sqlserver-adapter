module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Date < ActiveRecord::Type::Date

          def sqlserver_type
            'date'.freeze
          end

          def serialize(value)
            return unless value.present?
            return value if value.is_a?(Data)
            Data.new(super)
          end

          def deserialize(value)
            return value.value if value.is_a?(Data)
            super
          end

          def type_cast_for_schema(value)
            serialize(value).quoted
          end

          class Data

            attr_reader :value

            def initialize(value)
              @value = value
            end

            def quoted
              Utils.quote_string_single @value.to_s(:_sqlserver_dateformat)
            end

          end

        end
      end
    end
  end
end
