# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class UnicodeString < String
        end
      end
    end
  end
end
