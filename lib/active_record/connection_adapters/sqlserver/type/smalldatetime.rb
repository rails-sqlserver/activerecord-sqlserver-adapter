module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class SmallDateTime < DateTime

          def type
            :smalldatetime
          end


          private

          def cast_fractional(value)
            value.change usec: 0
          end

        end
      end
    end
  end
end
