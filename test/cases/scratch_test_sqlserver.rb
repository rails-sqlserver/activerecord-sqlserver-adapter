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
    posts = Post.count(:all, :include => [ :author, :comments ], :limit => 2, :offset => 10, :conditions => [ "authors.name = ?", 'David' ])
    assert_equal 0, posts
  end
  
  
  
end

