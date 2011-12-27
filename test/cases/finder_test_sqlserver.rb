require 'cases/sqlserver_helper'
require 'models/event'

class FinderTestSqlserver < ActiveRecord::TestCase
end

class FinderTest < ActiveRecord::TestCase
  
  COERCED_TESTS = [
    :test_string_sanitation,
    :test_first_and_last_with_integer_should_use_sql_limit
  ]
  
  include SqlserverCoercedTest
  
  def test_coerced_string_sanitation
    assert_not_equal "N'something ' 1=1'", ActiveRecord::Base.sanitize("something ' 1=1")
    assert_equal "N'something; select table'", ActiveRecord::Base.sanitize("something; select table")
  end
  
  def test_coerced_first_and_last_with_integer_should_use_sql_limit
    assert_sql(/TOP \(2\)/) { Topic.first(2).entries }
    assert_sql(/TOP \(5\)/) { Topic.last(5).entries }
  end
  
end

