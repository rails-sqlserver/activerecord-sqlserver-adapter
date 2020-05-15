# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Boolean < ActiveRecord::Type::Boolean
          def sqlserver_type
            "bit"
          end
        end
      end
    end
  end
end
