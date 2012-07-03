require 'cases/sqlserver_helper'
require 'models/book'
require 'models/post'

class OffsetAndLimitTestSqlserver < ActiveRecord::TestCase
  
  fixtures :posts
  
  setup     :create_10_books
  teardown  :destroy_all_books
  
  
  context 'When selecting with limit' do
  
    should 'alter sql to limit number of records returned' do
      assert_sql(/SELECT TOP \(10\)/) { Book.limit(10).all }
    end
  
  end
  
  context 'When selecting with offset' do

    should 'have limit (top) of 9223372036854775807 if only offset is passed' do
      assert_sql(/SELECT TOP \(9223372036854775807\) \[__rnt\]\.\* FROM.*WHERE \[__rnt\]\.\[__rn\] > \(1\)/) { Book.all(:offset=>1) }
    end
    
    should 'support calling exists?' do
      assert Book.offset(3).exists?
    end
    
  end
  
  context 'When selecting with limit and offset' do
    
    should 'work with fully qualified table and columns in select' do 
      books = Book.all :select => 'books.id, books.name', :limit => 3, :offset => 5
      assert_equal Book.all[5,3].map(&:id), books.map(&:id)
    end
    
    # ActiveRecord Regression 3.2.3?
    # https://github.com/rails/rails/commit/a2c2f406612a1855fbc6fe816cf3e15b4ef531d3#commitcomment-1208811
    should_eventually 'allow sql literal for offset' do
      assert_sql(/WHERE \[__rnt\]\.\[__rn\] > \(3-2\)/) { Book.limit(10).offset(Arel::Nodes::Ascending.new('3-2')).all }
      assert_sql(/WHERE \[__rnt\]\.\[__rn\] > \(SELECT 8 AS \[count\]\)/) do 
        books = Book.all :limit => 3, :offset => Arel.sql('SELECT 8 AS [count]')
        assert_equal 2, books.size, 'remember there are only 10 books and offset is 8'
      end
    end
    
    # ActiveRecord Regression 3.2.3?
    # https://github.com/rails/rails/commit/a2c2f406612a1855fbc6fe816cf3e15b4ef531d3#commitcomment-1208811
    should_eventually 'not convert strings which look like integers to integers' do
      assert_sql(/WHERE \[__rnt\]\.\[__rn\] > \(N''5''\)/) { Book.limit(10).offset('5').all }
    end

    should 'alter SQL to limit number of records returned offset by specified amount' do
      sql = %|EXEC sp_executesql N'SELECT TOP (3) [__rnt].* FROM ( SELECT ROW_NUMBER() OVER (ORDER BY [books].[id] ASC) AS [__rn], [books].* FROM [books] ) AS [__rnt] WHERE [__rnt].[__rn] > (5) ORDER BY [__rnt].[__rn] ASC'|
      assert_sql(sql) { Book.limit(3).offset(5).all }
    end
    
    should 'add locks to deepest sub select' do
      pattern = /FROM \[books\]\s+WITH \(NOLOCK\)/
      assert_sql(pattern) { Book.all :limit => 3, :offset => 5, :lock => 'WITH (NOLOCK)' }
      assert_sql(pattern) { Book.count :limit => 3, :offset => 5, :lock => 'WITH (NOLOCK)' }
    end
    
    should 'have valid sort order' do
      order_row_numbers = SqlServerOrderRowNumber.offset(7).order("c DESC").select("c, ROW_NUMBER() OVER (ORDER BY c ASC) AS [dummy]").all.map(&:c)
      assert_equal [2, 1, 0], order_row_numbers
    end
    
    context 'with count' do

      should 'pass a gauntlet of window tests' do
        Book.first.destroy
        Book.first.destroy
        Book.first.destroy
        assert_equal 7, Book.count
        assert_equal 1, Book.limit(1).offset(1).size
        assert_equal 1, Book.limit(1).offset(5).size
        assert_equal 1, Book.limit(1).offset(6).size
        assert_equal 0, Book.limit(1).offset(7).size
        assert_equal 3, Book.limit(3).offset(4).size
        assert_equal 2, Book.limit(3).offset(5).size
        assert_equal 1, Book.limit(3).offset(6).size
        assert_equal 0, Book.limit(3).offset(7).size
        assert_equal 0, Book.limit(3).offset(8).size
      end

    end

    context 'with uniq selection' do

      should 'add the distinct clause at the correct position' do
        assert_equal 5, Book.limit(5).offset(1).uniq.size
      end

    end
    
  end
  
  protected
  
  def create_10_books
    Book.delete_all
    @books = (1..10).map {|i| Book.create!}
  end
  
  def destroy_all_books
    @books.each { |b| b.destroy }
  end
  
end

