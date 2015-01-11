module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Float < ActiveRecord::Type::Float

          include Castable

        end
      end
    end
  end
end
