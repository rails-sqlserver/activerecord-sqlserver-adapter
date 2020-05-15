# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Real < Float
          def type
            :real
          end

          def sqlserver_type
            "real"
          end
        end
      end
    end
  end
end
