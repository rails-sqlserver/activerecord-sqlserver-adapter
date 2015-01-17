require 'cases/helper_sqlserver'
require 'models/person'

class MigrationTest < ActiveRecord::TestCase
  COERCED_TESTS = [:test_migrator_db_has_no_schema_migrations_table]
  include ARTest::SQLServer::CoercedTest

  # TODO: put a real test here
  def test_coerced_test_migrator_db_has_no_schema_migrations_table
    assert true
  end

end
