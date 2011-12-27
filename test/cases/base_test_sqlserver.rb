require 'cases/sqlserver_helper'

class BasicsTest < ActiveRecord::TestCase
  
  COERCED_TESTS = [:test_column_names_are_escaped]
  
  include SqlserverCoercedTest
  
  def test_coerced_column_names_are_escaped
    assert_equal "[foo]]bar]", ActiveRecord::Base.connection.quote_column_name("foo]bar")
  end
  
end

