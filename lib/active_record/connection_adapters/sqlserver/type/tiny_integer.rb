# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class TinyInteger < Integer
          def sqlserver_type
            "tinyint"
          end

          private

          def max_value
            256
          end

          def min_value
            0
          end
        end
      end
    end
  end
end
