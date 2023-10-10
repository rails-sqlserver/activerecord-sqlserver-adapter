# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module AbstractAdapter
          def sqlserver?
            false
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  mod = ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::AbstractAdapter
  ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(mod)
end
