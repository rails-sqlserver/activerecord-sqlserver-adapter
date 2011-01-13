require 'cases/sqlserver_helper'
require 'models/task'
require 'models/book'
require 'models/post'

class ScratchTestSqlserver < ActiveRecord::TestCase
  
  fixtures :tasks, :posts
  
  setup :create_10_books
  
  
  should 'pass' do
    raise Book.all(:offset=>1).inspect
  end
  
  
  protected
  
  def create_10_books
    Book.delete_all
    @books = (1..10).map{ |i| Book.create! }
  end
  
  
end

