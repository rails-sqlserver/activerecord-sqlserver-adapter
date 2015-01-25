module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Timestamp < Binary

          def type
            :ss_timestamp
          end

        end
      end
    end
  end
end
