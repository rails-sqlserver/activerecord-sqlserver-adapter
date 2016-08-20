module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeChar < UnicodeString

          def type
            :nchar
          end

          def sqlserver_type
            'nchar'.tap do |type|
              type << "(#{limit})" if limit
            end
          end

        end
      end
    end
  end
end
