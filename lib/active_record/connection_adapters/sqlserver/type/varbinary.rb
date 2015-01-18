module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Varbinary < Binary

          def initialize(options = {})
            super
            @limit = 8000 if @limit.to_i == 0
          end

          def type
            :varbinary
          end

        end
      end
    end
  end
end
