require 'cases/sqlserver_helper'
require 'models/tag'
require 'models/tagging'
require 'models/post'
require 'models/item'
require 'models/comment'
require 'models/author'
require 'models/category'
require 'models/categorization'
require 'models/vertex'
require 'models/edge'
require 'models/book'
require 'models/citation'

class ScratchTestSqlserver < ActiveRecord::TestCase
  
  self.use_transactional_fixtures = false
  
  fixtures :posts, :authors, :categories, :categorizations, :comments, :tags, :taggings, 
           :author_favorites, :vertices, :items, :books, :edges
  
  should 'pass' do
    assert_equal 1, posts(:welcome).tags.count
  end
  
  
end

