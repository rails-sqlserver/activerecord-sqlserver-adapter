# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeVarchar < UnicodeChar
          def initialize(**args)
            super
            @limit = 4000 if @limit.to_i == 0
          end

          def type
            :string
          end

          def sqlserver_type
            "nvarchar".yield_self do |type|
              type += "(#{limit})" if limit
              type
            end
          end
        end
      end
    end
  end
end
