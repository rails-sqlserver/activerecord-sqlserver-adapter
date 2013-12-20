require 'cases/sqlserver_helper'
require 'models/developer'

class MethodScopingTestSqlServer < ActiveRecord::TestCase
end

class NestedScopingTest < ActiveRecord::TestCase
  
  COERCED_TESTS = [:test_merged_scoped_find]
  
  include SqlserverCoercedTest
  
  fixtures :developers

  # TODO update test for rails 4
  def test_coerced_test_merged_scoped_find
    poor_jamis = developers(:poor_jamis)
    Developer.where("salary < 100000").scoping do
      Developer.offset(1).order('id asc').scoping do
        assert_sql /ORDER BY id asc/i do
          assert_equal(poor_jamis, Developer.order('id asc').first)
        end
      end
    end
  end
  
end


