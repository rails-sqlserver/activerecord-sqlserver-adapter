module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Timestamp < Binary

          def type
            :ss_timestamp
          end

          def sqlserver_type
            'timestamp'.freeze
          end

        end
      end
    end
  end
end
