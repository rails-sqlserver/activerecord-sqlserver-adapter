# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Text < VarcharMax
          def type
            :text_basic
          end

          def sqlserver_type
            "text"
          end
        end
      end
    end
  end
end
