module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class VarbinaryMax < Varbinary

          def initialize(options = {})
            super
            @limit = 2_147_483_647
          end

        end
      end
    end
  end
end
