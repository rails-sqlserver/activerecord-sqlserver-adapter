require 'cases/sqlserver_helper'

class ValidationsTestSqlserver < ActiveRecord::TestCase
end

class ValidationsTest < ActiveRecord::TestCase
  
  COERCED_TESTS = [:test_validate_uniqueness_with_limit_and_utf8]
  
  include SqlserverCoercedTest
  
  def test_coerced_test_validate_uniqueness_with_limit_and_utf8
    true
  end
  
  
end

