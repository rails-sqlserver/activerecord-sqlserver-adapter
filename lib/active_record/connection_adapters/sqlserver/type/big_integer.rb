module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class BigInteger < Integer

          DEFAULT_LIMIT = 8

          def sqlserver_type
            'bigint'.freeze
          end

          private

          def min_value
            -9_223_372_036_854_775_808
          end

          def max_value
            9_223_372_036_854_775_808
          end

        end
      end
    end
  end
end
