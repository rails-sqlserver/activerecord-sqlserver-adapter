# frozen_string_literal: true

require "active_record/associations/preloader"

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module LoaderQuery
          def load_records_for_keys(keys, &block)
            return super unless scope.connection.adapter_name == "SQLServer"

            keys.each_slice(in_clause_length).flat_map do |slice|
              scope.where(association_key_name => slice).load(&block).records
            end
          end

          def in_clause_length
            10_000
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  mod = ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::LoaderQuery
  ActiveRecord::Associations::Preloader::Association::LoaderQuery.prepend(mod)
end
