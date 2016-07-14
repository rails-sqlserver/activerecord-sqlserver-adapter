module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Timestamp < Binary

          SQLSERVER_TYPE = 'timestamp'.freeze

          def type
            :ss_timestamp
          end

        end
      end
    end
  end
end
