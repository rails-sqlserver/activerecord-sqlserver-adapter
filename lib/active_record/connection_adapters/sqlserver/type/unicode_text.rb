module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeText < UnicodeVarcharMax

          def type
            :ntext
          end

          def sqlserver_type
            'ntext'.freeze
          end

        end
      end
    end
  end
end
