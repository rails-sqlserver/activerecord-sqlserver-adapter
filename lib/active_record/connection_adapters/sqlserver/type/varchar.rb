# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Varchar < Char
          def initialize(**args)
            super
            @limit = 8000 if @limit.to_i == 0
          end

          def type
            :varchar
          end

          def sqlserver_type
            "varchar".yield_self do |type|
              type += "(#{limit})" if limit
              type
            end
          end
        end
      end
    end
  end
end
