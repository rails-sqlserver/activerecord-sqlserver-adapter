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
            return value if value.acts_like?(:string)
            value.to_s(:_sqlserver_dateformat)
          end

          def type_cast_for_schema(value)
            serialize(value).inspect
          end

        end
      end
    end
  end
end
