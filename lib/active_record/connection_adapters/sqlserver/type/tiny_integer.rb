module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class TinyInteger < Integer


          private

          def max_value
            256
          end

          def min_value
            0
          end

        end
      end
    end
  end
end
