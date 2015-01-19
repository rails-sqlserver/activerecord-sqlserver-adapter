module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeChar < UnicodeString

          def type
            :nchar
          end

        end
      end
    end
  end
end
