module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class BigInteger < Integer

          def type
            :bigint
          end

          def sqlserver_type
            'bigint'.freeze
          end

        end
      end
    end
  end
end
