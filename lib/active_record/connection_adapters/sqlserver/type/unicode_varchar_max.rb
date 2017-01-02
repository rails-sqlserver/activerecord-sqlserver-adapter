module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeVarcharMax < UnicodeVarchar

          def initialize(*args)
            super
            @limit = 2_147_483_647
          end

          def type
            :text
          end

          def sqlserver_type
            'nvarchar(max)'.freeze
          end

        end
      end
    end
  end
end
