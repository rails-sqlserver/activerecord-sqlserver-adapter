# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeText < UnicodeVarcharMax
          def type
            :ntext
          end

          def sqlserver_type
            "ntext"
          end
        end
      end
    end
  end
end
