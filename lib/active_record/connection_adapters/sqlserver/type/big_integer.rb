module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class BigInteger < Integer

          def type
            :bigint
          end

        end
      end
    end
  end
end
