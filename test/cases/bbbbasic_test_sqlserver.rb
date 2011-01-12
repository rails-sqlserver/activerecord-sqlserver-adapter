require 'cases/sqlserver_helper'
require 'models/task'
require 'models/book'
require 'models/post'

class BBBBasicTestSqlserver < ActiveRecord::TestCase
  
  fixtures :tasks, :posts
  
  setup :create_10_books
  
  
  should 'pass limit' do
    Book.count :limit => 3, :offset => 5, :lock => 'WITH (NOLOCK)'
  end
  
  
  protected
  
  def create_10_books
    Book.delete_all
    @books = (1..10).map{ |i| Book.create! }
  end
  
  
end

