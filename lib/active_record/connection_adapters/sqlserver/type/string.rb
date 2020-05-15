# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class String < ActiveRecord::Type::String
          def changed_in_place?(raw_old_value, new_value)
            if raw_old_value.is_a?(Data)
              raw_old_value.value != new_value
            else
              super
            end
          end
        end
      end
    end
  end
end
