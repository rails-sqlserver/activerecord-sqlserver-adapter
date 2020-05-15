# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeChar < UnicodeString
          def type
            :nchar
          end

          def sqlserver_type
            "nchar".yield_self do |type|
              type += "(#{limit})" if limit
              type
            end
          end
        end
      end
    end
  end
end
