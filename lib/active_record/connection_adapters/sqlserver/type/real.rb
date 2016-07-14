module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Real < Float

          SQLSERVER_TYPE = 'real'.freeze

          def type
            :real
          end

        end
      end
    end
  end
end
