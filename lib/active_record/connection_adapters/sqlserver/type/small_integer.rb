module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class SmallInteger < Integer

          SQLSERVER_TYPE = 'smallint'.freeze

        end
      end
    end
  end
end
