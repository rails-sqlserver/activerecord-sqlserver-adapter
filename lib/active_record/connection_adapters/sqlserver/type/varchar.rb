module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Varchar < Char

          def initialize(options = {})
            super
            @limit = 8000 if @limit.to_i == 0
          end

          def type
            :varchar
          end

        end
      end
    end
  end
end
