module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeText < UnicodeVarcharMax

          SQLSERVER_TYPE = 'ntext'.freeze

          def type
            :ntext
          end

          def sqlserver_type
            SQLSERVER_TYPE
          end

        end
      end
    end
  end
end
