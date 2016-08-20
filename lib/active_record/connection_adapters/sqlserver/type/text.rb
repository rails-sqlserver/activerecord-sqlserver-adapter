module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Text < VarcharMax

          def type
            :text_basic
          end

          def sqlserver_type
            'text'.freeze
          end

        end
      end
    end
  end
end
