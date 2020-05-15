# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Float < ActiveRecord::Type::Float
          def type
            :float
          end

          def sqlserver_type
            "float"
          end
        end
      end
    end
  end
end
