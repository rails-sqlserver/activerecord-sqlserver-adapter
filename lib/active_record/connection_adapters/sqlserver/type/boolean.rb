module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Boolean < ActiveRecord::Type::Boolean

          SQLSERVER_TYPE = 'bit'.freeze

        end
      end
    end
  end
end
