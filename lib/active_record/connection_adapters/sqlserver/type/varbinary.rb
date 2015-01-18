module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Varbinary < Binary

          def type
            :varbinary
          end

        end
      end
    end
  end
end
