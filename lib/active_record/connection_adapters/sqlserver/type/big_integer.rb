module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class BigInteger < Integer

          SQLSERVER_TYPE = 'bigint'.freeze

          def type
            :bigint
          end

        end
      end
    end
  end
end
