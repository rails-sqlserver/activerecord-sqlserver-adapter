module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        module Castable

          def type_cast_from_database(value)
            type_cast_from_ss_database? ? super : value
          end

        end
      end
    end
  end
end
