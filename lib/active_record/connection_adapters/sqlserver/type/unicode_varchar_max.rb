module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeVarcharMax < UnicodeVarchar

          SQLSERVER_TYPE = 'nvarchar(max)'.freeze

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
