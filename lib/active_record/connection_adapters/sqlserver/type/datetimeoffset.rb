module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class DateTimeOffset < DateTime2

          def type
            :datetimeoffset
          end

          def type_cast_for_database(value)
            return super unless value.acts_like?(:time)
            value.to_s :_sqlserver_datetimeoffset
          end

          def type_cast_for_schema(value)
            type_cast_for_database(value).inspect
          end


          private

          def zone_conversion(value)
            value
          end

        end
      end
    end
  end
end
