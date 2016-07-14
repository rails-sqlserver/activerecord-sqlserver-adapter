module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class VarcharMax < Varchar

          SQLSERVER_TYPE = 'varchar(max)'.freeze

          def initialize(options = {})
            super
            @limit = 2_147_483_647
          end

          def type
            :varchar_max
          end

        end
      end
    end
  end
end
