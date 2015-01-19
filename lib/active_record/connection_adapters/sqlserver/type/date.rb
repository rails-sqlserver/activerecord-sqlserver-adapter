module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Date < ActiveRecord::Type::Date

          # When FreeTDS/TinyTDS casts this data type natively.
          # include Castable

        end
      end
    end
  end
end
