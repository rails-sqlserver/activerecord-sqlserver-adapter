module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Binary < ActiveRecord::Type::Binary

          def type
            :binary_basic
          end

          def sqlserver_type
            'binary'.tap do |type|
              type << "(#{limit})" if limit
            end
          end

        end
      end
    end
  end
end
