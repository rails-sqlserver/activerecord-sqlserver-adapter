module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Float < ActiveRecord::Type::Float

          include Castable

          def initialize(options = {})
            super
            @limit ||= 24
          end

        end
      end
    end
  end
end
