# frozen_string_literal: true

class SSTestDatatypeMigration < ActiveRecord::Base
  self.table_name = :sst_datatypes_migration
end

class SSTestDatatypeMigrationJson < ActiveRecord::Base
  self.table_name = :sst_datatypes_migration
  attribute :json_col, ActiveRecord::Type::SQLServer::Json.new
end
