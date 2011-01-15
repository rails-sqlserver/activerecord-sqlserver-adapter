require 'cases/sqlserver_helper'
require 'models/post'
require 'models/tagging'
require 'models/tag'
require 'models/comment'
require 'models/author'
require 'models/category'
require 'models/company'
require 'models/person'
require 'models/reader'
require 'models/owner'
require 'models/pet'
require 'models/reference'
require 'models/job'
require 'models/subscriber'
require 'models/subscription'
require 'models/book'
require 'models/developer'
require 'models/project'

class ScratchTestSqlserver < ActiveRecord::TestCase

  fixtures :posts, :comments, :authors, :author_addresses, :categories, :categories_posts,
            :companies, :accounts, :tags, :taggings, :people, :readers,
            :owners, :pets, :author_favorites, :jobs, :references, :subscribers, :subscriptions, :books,
            :developers, :projects, :developers_projects
  
  should 'pass' do
    comments = Comment.find(:all, :include => :post, :limit => 3, :offset => 2, :order => 'comments.id')
    assert_equal 3, comments.length
    assert_equal [3,5,6], comments.collect { |c| c.id }
  end
  
  
  
end

