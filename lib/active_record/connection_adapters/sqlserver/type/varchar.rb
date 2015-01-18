module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Varchar < Char

          def type
            :varchar
          end


        end
      end
    end
  end
end
