module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Float < ActiveRecord::Type::Float

          SQLSERVER_TYPE = 'float'.freeze

          def type
            :float
          end

        end
      end
    end
  end
end
