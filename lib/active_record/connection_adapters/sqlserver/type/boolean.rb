module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Boolean < ActiveRecord::Type::Boolean

          include Castable

        end
      end
    end
  end
end
