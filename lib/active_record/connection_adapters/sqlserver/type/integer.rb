# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Integer < ActiveRecord::Type::Integer
          def sqlserver_type
            "int"
          end
        end
      end
    end
  end
end
