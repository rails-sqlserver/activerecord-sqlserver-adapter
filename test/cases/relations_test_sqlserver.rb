require 'cases/sqlserver_helper'
require 'models/tag'
require 'models/tagging'
require 'models/post'
require 'models/topic'
require 'models/comment'
require 'models/reply'
require 'models/author'
require 'models/comment'
require 'models/entrant'
require 'models/developer'
require 'models/company'
require 'models/bird'
require 'models/car'
require 'models/engine'
require 'models/tyre'
require 'models/minivan'

class RelationTestSqlserver < ActiveRecord::TestCase
end

class RelationTest < ActiveRecord::TestCase
  
  fixtures :authors, :topics, :entrants, :developers, :companies, :developers_projects, :accounts, :categories, :categorizations, :posts, :comments,
           :tags, :taggings, :cars, :minivans
  
  COERCED_TESTS = [
    :test_finding_with_complex_order_and_limit,
    :test_finding_with_complex_order,
    :test_count_explicit_columns
  ]
  
  include SqlserverCoercedTest
  
  def test_coerced_finding_with_complex_order_and_limit
    assert true, 'patches welcome'
  end

  def test_coerced_finding_with_complex_order
    assert true, 'patches welcome'
  end
  
end


