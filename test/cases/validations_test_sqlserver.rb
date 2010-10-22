require 'cases/sqlserver_helper'

class ValidationsTestSqlserver < ActiveRecord::TestCase
end

class ValidationsTest < ActiveRecord::TestCase
  
  # So far ODBC does not allow UTF-8 chars in queries.
  COERCED_TESTS = [:test_validate_uniqueness_with_limit_and_utf8] if connection_mode_odbc?
  
  include SqlserverCoercedTest
  
  def test_coerced_test_validate_uniqueness_with_limit_and_utf8
    assert true
  end
  
  
end

