module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Text < VarcharMax

          SQLSERVER_TYPE = 'text'.freeze

          def type
            :text_basic
          end

          def sqlserver_type
            SQLSERVER_TYPE
          end

        end
      end
    end
  end
end
