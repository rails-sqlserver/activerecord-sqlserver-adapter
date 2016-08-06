module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Integer < ActiveRecord::Type::Integer

          def sqlserver_type
            'int'.freeze
          end

        end
      end
    end
  end
end
