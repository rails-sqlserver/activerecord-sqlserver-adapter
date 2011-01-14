require 'cases/sqlserver_helper'
require 'models/post'
require 'models/author'
require 'models/project'
require 'models/developer'

class ScratchTestSqlserver < ActiveRecord::TestCase
  
  fixtures :posts, :authors, :projects, :developers
  
  
  should 'pass' do
    jack = Author.new :name => "Jack"
    post = jack.posts_with_callbacks.build :title => "Call me back!", :body => "Before you wake up and after you sleep"

    callback_log = ["before_adding<new>", "after_adding#{jack.posts_with_callbacks.first.id}"]
    assert_equal callback_log, jack.post_log
    assert jack.save
    
    # SELECT COUNT([count]) AS [count_id] 
    # FROM ( 
    #   SELECT ROW_NUMBER() OVER (ORDER BY [posts].[id] ASC) AS [__rn], 
    #   1 AS [count] 
    #   FROM [posts]  
    #   WHERE ([posts].author_id = 3) 
    # ) AS [__rnt] NULL
    
    assert_equal 1, jack.posts_with_callbacks.count
    assert_equal callback_log, jack.post_log
  end
  
  
  
  
end

