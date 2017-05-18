module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class BigInteger < Integer

          def sqlserver_type
            'bigint'.freeze
          end

        end
      end
    end
  end
end
