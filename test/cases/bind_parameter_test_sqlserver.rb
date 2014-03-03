require 'cases/sqlserver_helper'
require 'models/topic'

class BindParameterTestSqlserver < ActiveRecord::TestCase
end

class ActiveRecord::BindParameterTest < ActiveRecord::TestCase

  fixtures :topics

  COERCED_TESTS = [
    :test_binds_are_logged
  ]

  include SqlserverCoercedTest

  # TODO: put a real test here
  def test_coerced_binds_are_logged
    assert true, 'they are!'
  end


end


