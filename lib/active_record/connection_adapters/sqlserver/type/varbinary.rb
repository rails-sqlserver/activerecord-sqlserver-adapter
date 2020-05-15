# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Varbinary < Binary
          def initialize(**args)
            super
            @limit = 8000 if @limit.to_i == 0
          end

          def type
            :varbinary
          end

          def sqlserver_type
            "varbinary".yield_self do |type|
              type += "(#{limit})" if limit
              type
            end
          end
        end
      end
    end
  end
end
