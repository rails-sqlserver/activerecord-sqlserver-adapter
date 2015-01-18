module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Text < VarcharMax

          def type
            :text_basic
          end

        end
      end
    end
  end
end
