module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeVarcharMax < UnicodeVarchar

          def initialize(options = {})
            super
            @limit = 2_147_483_647
          end

          def type
            :text
          end

        end
      end
    end
  end
end
