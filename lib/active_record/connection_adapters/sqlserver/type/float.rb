module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Float < ActiveRecord::Type::Float

          def type
            :float
          end

          def sqlserver_type
            'float'.freeze
          end

        end
      end
    end
  end
end
