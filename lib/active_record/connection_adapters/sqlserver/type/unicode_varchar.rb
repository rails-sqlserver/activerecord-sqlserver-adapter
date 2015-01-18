module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeVarchar < UnicodeChar

          def initialize(options = {})
            super
            @limit = 4000 if @limit.to_i == 0
          end

          def type
            :string
          end

        end
      end
    end
  end
end
