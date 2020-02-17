module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class String < ActiveRecord::Type::String

          def deserialize(value)
            super(value)&.strip
          end


        end
      end
    end
  end
end
