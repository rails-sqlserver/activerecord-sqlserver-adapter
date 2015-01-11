module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Decimal < ActiveRecord::Type::Decimal

          include Castable

        end
      end
    end
  end
end
