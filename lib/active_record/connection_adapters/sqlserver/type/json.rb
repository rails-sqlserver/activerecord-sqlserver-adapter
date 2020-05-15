# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        class Json < ActiveRecord::Type::Json
        end
      end
    end
  end
end
