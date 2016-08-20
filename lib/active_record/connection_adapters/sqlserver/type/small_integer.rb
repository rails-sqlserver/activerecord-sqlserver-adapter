module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class SmallInteger < Integer

          def sqlserver_type
            'smallint'.freeze
          end

        end
      end
    end
  end
end
