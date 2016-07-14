module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class DateTime2 < DateTime

          include TimeValueFractional2

          def type
            :datetime2
          end

          def sqlserver_type
            "datetime2(#{precision.to_i})"
          end

        end
      end
    end
  end
end
