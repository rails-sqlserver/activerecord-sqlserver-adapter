module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeVarchar < UnicodeChar

          def type
            :string
          end

        end
      end
    end
  end
end
