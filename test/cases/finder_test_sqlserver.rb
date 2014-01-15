require 'cases/sqlserver_helper'
require 'models/event'
require 'models/author'
require 'models/post'
require 'models_sqlserver/topic'

class FinderTestSqlserver < ActiveRecord::TestCase
end

class FinderTest < ActiveRecord::TestCase
  fixtures :authors, :author_addresses, :posts
  COERCED_TESTS = [
    :test_exists_does_not_select_columns_without_alias,
    :test_string_sanitation,
    :test_take_and_first_and_last_with_integer_should_use_sql_limit,
    :test_find_with_order_on_included_associations_with_construct_finder_sql_for_association_limiting_and_is_distinct
 
  ]

  include SqlserverCoercedTest


  def test_coerced_find_with_order_on_included_associations_with_construct_finder_sql_for_association_limiting_and_is_distinct
   p =  Post.all.merge!(:includes => { :authors => :author_address }, 
      :order => 'author_addresses.id DESC ', 
      :limit => 2)    
    arel_to_png(p)
    assert_equal 2, p.to_a.size
    puts "*****#{ActiveRecord::SQLCounter.log_all.join("\n\n")}"
 
    assert_equal 3, Post.all.merge!(:includes => { :author => :author_address, :authors => :author_address},
                              :order => 'author_addresses_authors.id DESC ', :limit => 3).to_a.size
  end


  def test_coerced_exists_does_not_select_columns_without_alias
    assert_sql(/SELECT TOP \(1\) 1 AS one FROM \[topics\]/i) do
      Topic.exists?
    end
  end

  def test_coerced_string_sanitation
    assert_not_equal "N'something ' 1=1'", ActiveRecord::Base.sanitize("something ' 1=1")
    assert_equal "N'something; select table'", ActiveRecord::Base.sanitize("something; select table")
  end

  def test_coerced_take_and_first_and_last_with_integer_should_use_sql_limit
    assert_sql(/TOP \(3\)/) { Topic.take(3).entries }
    assert_sql(/TOP \(2\)/) { Topic.first(2).entries }
    assert_sql(/TOP \(5\)/) { Topic.last(5).entries }
  end
end

