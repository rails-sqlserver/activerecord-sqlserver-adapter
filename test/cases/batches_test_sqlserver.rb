require 'cases/sqlserver_helper'
require 'models/post'

class BatchesTestSqlserver < ActiveRecord::TestCase
end

class EachTest < ActiveRecord::TestCase
  
  COERCED_TESTS = [
    :test_find_in_batches_should_quote_batch_order
  ]
  
  include SqlserverCoercedTest
  
  fixtures :posts
  
  def test_coerced_find_in_batches_should_quote_batch_order
    c = Post.connection
    assert_sql(/ORDER BY \[posts\]\.\[id\]/) do
      Post.find_in_batches(:batch_size => 1) do |batch|
        assert_kind_of Array, batch
        assert_kind_of Post, batch.first
      end
    end
  end
  
  
end
