module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Char < String

          def type
            :char
          end

        end
      end
    end
  end
end
