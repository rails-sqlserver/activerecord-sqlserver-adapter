module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Real < Float

          def type
            :real
          end

        end
      end
    end
  end
end
