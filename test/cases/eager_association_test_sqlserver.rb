require 'cases/sqlserver_helper'
require 'models/post'
require 'models/author'
require 'models/comment'

class EagerAssociationTestSqlserver < ActiveRecord::TestCase
end

class EagerAssociationTest < ActiveRecord::TestCase
  
  COERCED_TESTS = [
    :test_count_with_include
  ]
  
  include SqlserverCoercedTest
  
  fixtures :authors, :posts, :comments
  
  def test_coerced_test_count_with_include
    assert_equal 3, authors(:david).posts_with_comments.count(:conditions => "len(comments.body) > 15")
  end
  
  
end
