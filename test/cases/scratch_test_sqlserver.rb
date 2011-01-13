require 'cases/sqlserver_helper'
require 'models/task'
require 'models/book'
require 'models/post'

class ScratchTestSqlserver < ActiveRecord::TestCase
  
  fixtures :tasks, :posts
  
  setup :create_10_books
  
  
  should 'pass' do
    Book.all :limit => 3, :offset => 5, :lock => 'WITH (NOLOCK)'
    Book.count :limit => 3, :offset => 5, :lock => 'WITH (NOLOCK)'
    # pattern = /FROM \[books\] WITH \(NOLOCK\)/
    # assert_sql(pattern) { Book.all :limit => 3, :offset => 5, :lock => 'WITH (NOLOCK)' }
    # assert_sql(pattern) { Book.count :limit => 3, :offset => 5, :lock => 'WITH (NOLOCK)' }
  end
  
  
  protected
  
  def create_10_books
    Book.delete_all
    @books = (1..10).map{ |i| Book.create! }
  end
  
  
end

