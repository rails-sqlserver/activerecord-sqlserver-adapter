module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Integer < ActiveRecord::Type::Integer

          SQLSERVER_TYPE = 'int'.freeze

        end
      end
    end
  end
end
