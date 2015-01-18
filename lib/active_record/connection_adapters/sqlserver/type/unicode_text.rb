module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeText < UnicodeVarcharMax

          def type
            :ntext
          end

        end
      end
    end
  end
end
