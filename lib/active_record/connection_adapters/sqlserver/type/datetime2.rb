# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class DateTime2 < DateTime
          include TimeValueFractional2

          def sqlserver_type
            "datetime2(#{precision.to_i})"
          end
        end
      end
    end
  end
end
