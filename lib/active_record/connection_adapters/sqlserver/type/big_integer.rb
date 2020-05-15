# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class BigInteger < Integer
          def sqlserver_type
            "bigint"
          end
        end
      end
    end
  end
end
