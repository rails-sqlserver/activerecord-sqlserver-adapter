module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Type
        module Sql

          def sqlserver_type
            defined?(SQLSERVER_TYPE) ? SQLSERVER_TYPE : type.to_s
          end

        end
        ::ActiveModel::Type::Value.include SQLServer::Type::Sql
      end
    end
  end
end
