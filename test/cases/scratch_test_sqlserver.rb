require 'cases/sqlserver_helper'
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

class ScratchTestSqlserver < ActiveRecord::TestCase

  fixtures :topics, :companies, :developers, :projects, :computers, :accounts, :minimalistics, 'warehouse-things', 
           :authors, :categorizations, :categories, :posts
  
  should 'pass' do
    topics = Topic.send(:with_scope, :find => {:limit => 1, :offset => 1, :include => :replies}) do
      Topic.find(:all, :order => "topics.id")
    end
    assert_equal 1, topics.size
    assert_equal 2, topics.first.id
  end
  
  
  
end

