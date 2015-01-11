module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Integer < ActiveRecord::Type::Integer

          include Castable

        end
      end
    end
  end
end
