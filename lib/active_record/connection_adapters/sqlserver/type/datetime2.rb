module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class DateTime2 < DateTime

          include TimeValueFractional2

          def type
            :datetime2
          end

        end
      end
    end
  end
end
