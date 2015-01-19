module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class SmallDateTime < DateTime

          include Castable


          private

          def cast_usec(value)
            0
          end

          def cast_usec_for_database(value)
            '.000'
          end

        end
      end
    end
  end
end
