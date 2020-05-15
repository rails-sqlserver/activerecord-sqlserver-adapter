# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class SmallInteger < Integer
          def sqlserver_type
            "smallint"
          end
        end
      end
    end
  end
end
