module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeVarchar < UnicodeChar

          def initialize(*args)
            super
            @limit = 4000 if @limit.to_i == 0
          end

          def type
            :string
          end

          def sqlserver_type
            'nvarchar'.tap do |type|
              type << "(#{limit})" if limit
            end
          end

        end
      end
    end
  end
end
