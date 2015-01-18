module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Binary < ActiveRecord::Type::Binary

          def type
            :binary_basic
          end

        end
      end
    end
  end
end
