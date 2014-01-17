require 'cases/sqlserver_helper'
require 'models/post'
require 'models/comment'

module ActiveRecord
  class WhereChainTest < ActiveRecord::TestCase
    include SqlserverCoercedTest

    COERCED_TESTS = [:test_not_eq_with_array_parameter]

    def test_coerced_not_eq_with_array_parameter
      expected = Arel::Nodes::Not.new("title = N'hello'")
      relation = Post.where.not(['title = ?', 'hello'])
      assert_equal([expected], relation.where_values)
    end
  end
end