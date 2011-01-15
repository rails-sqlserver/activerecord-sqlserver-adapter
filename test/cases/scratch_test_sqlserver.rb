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
    Post.send(:with_scope, :find => { :conditions => "1=1" }) do
      posts = authors(:david).posts.find(:all,
        :include    => :comments,
        :conditions => "comments.body like 'Normal%' OR comments.#{QUOTED_TYPE}= 'SpecialComment'",
        :limit      => 2
      )
      assert_equal 2, posts.size

      count = Post.count(
        :include    => [ :comments, :author ],
        :conditions => "authors.name = 'David' AND (comments.body like 'Normal%' OR comments.#{QUOTED_TYPE}= 'SpecialComment')",
        :limit      => 2
      )
      assert_equal count, posts.size
    end
  end
  
  
  
end

