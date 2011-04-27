# The filename begins with "aaaa" to ensure this is the first test.
require 'cases/sqlserver_helper'

class AAAACreateTablesTestSqlserver < ActiveRecord::TestCase
  
  self.use_transactional_fixtures = false
  
  should 'load activerecord schema then sqlserver specific schema' do
    # Core AR.
    schema_file = "#{ACTIVERECORD_TEST_ROOT}/schema/schema.rb"
    eval(File.read(schema_file))
    assert true
    # SQL Server.
    sqlserver_specific_schema_file = "#{SQLSERVER_SCHEMA_ROOT}/sqlserver_specific_schema.rb"
    eval(File.read(sqlserver_specific_schema_file))
    assert true
  end
  
end
