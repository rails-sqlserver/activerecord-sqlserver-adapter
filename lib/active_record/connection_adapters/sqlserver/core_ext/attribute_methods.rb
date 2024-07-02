# frozen_string_literal: true

require "active_record/attribute_methods"

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module AttributeMethods
          private

          def attributes_for_update(attribute_names)
            self.class.with_connection do |connection|
              return super(attribute_names) unless connection.sqlserver?

              super(attribute_names).reject do |name|
                column = self.class.columns_hash[name]
                column && column.respond_to?(:is_identity?) && column.is_identity?
              end
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
