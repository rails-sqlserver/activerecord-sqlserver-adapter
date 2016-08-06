module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Boolean < ActiveRecord::Type::Boolean

          def sqlserver_type
            'bit'.freeze
          end

        end
      end
    end
  end
end
