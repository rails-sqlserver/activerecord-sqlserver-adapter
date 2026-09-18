# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module JSONSchemaCacheSerializer
        ::ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer.register("sqlserver_column", ActiveRecord::ConnectionAdapters::SQLServer::Column)
        ::ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer.register("sqlserver_unicode_varchar", ActiveRecord::ConnectionAdapters::SQLServer::Type::UnicodeVarchar)
        ::ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer.register("sqlserver_type_metadata", ActiveRecord::ConnectionAdapters::SQLServer::TypeMetadata)
        ::ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer.register("sqlserver_datatime2", ActiveRecord::ConnectionAdapters::SQLServer::Type::DateTime2)
        ::ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer.register("sqlserver_datetime", ActiveRecord::ConnectionAdapters::SQLServer::Type::DateTime)
        ::ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer.register("sqlserver_time", ActiveRecord::ConnectionAdapters::SQLServer::Type::Time)
        ::ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer.register("sqlserver_big_interger", ActiveRecord::ConnectionAdapters::SQLServer::Type::BigInteger)
        ::ActiveRecord::ConnectionAdapters::JSONSchemaCacheSerializer.register("sqlserver_integer", ActiveRecord::ConnectionAdapters::SQLServer::Type::Integer)
      end
    end
  end
end
