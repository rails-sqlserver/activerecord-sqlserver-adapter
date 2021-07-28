# frozen_string_literal: true

require "active_record/attribute_methods"

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module AttributeMethods
          private

          def attributes_for_update(attribute_names)
            return super unless self.class.connection.adapter_name == "SQLServer"

            super.reject do |name|
              column = self.class.columns_hash[name]
              column && column.respond_to?(:is_identity?) && column.is_identity?
            end
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  include ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::AttributeMethods
end
