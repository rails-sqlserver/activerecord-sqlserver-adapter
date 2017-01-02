module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Varbinary < Binary

          def initialize(*args)
            super
            @limit = 8000 if @limit.to_i == 0
          end

          def type
            :varbinary
          end

          def sqlserver_type
            'varbinary'.tap do |type|
              type << "(#{limit})" if limit
            end
          end

        end
      end
    end
  end
end
