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
    combined = Developer.find(:all, :order => 'developers.name, developers.salary')
    assert_equal combined, Developer.find(:all, :order => ['developers.name', 'developers.salary'])
  end
  
  
end

