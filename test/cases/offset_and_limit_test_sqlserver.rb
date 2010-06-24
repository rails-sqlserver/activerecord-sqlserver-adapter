require 'cases/sqlserver_helper'
require 'models/book'

class OffsetAndLimitTestSqlserver < ActiveRecord::TestCase
  
  class Account < ActiveRecord::Base; end
  
  setup     :create_10_books
  teardown  :destroy_all_books
  
  
  context 'When selecting with limit' do
  
    should 'alter sql to limit number of records returned' do
      assert_sql(/SELECT TOP \(10\)/) { Book.limit(10).all }
    end
  
    should 'only allow integers for limit' do
      assert_sql(/SELECT TOP \(20\)/) { Book.limit('20-twenty').all }
    end
  
  end
  
  context 'When selecting with offset' do

    should 'have no limit (top) if only offset is passed' do
      assert_sql(/SELECT \[_rnt\]\.\* FROM.*WHERE \[_rnt\]\.\[rn\] > 1/) { Book.all(:offset=>1) }
    end

  end
  
  context 'When selecting with limit and offset' do
    
    should 'only allow integers for offset' do
      assert_sql(/WHERE \[_rnt\]\.\[rn\] > 0/) { Book.limit(10).offset('five').all }
    end
    
    should 'convert strings which look like integers to integers' do
      assert_sql(/WHERE \[_rnt\]\.\[rn\] > 5/) { Book.limit(10).offset('5').all }
    end

    should 'alter SQL to limit number of records returned offset by specified amount' do
      sql = %|SELECT TOP (3) [_rnt].* 
              FROM (
                SELECT ROW_NUMBER() OVER (ORDER BY [books].[id]) AS [rn], [books].* 
                FROM [books]
              ) AS [_rnt]
              WHERE [_rnt].[rn] > 5|.squish
      assert_sql(sql) { Book.limit(3).offset(5).all }
    end
    
    should_eventually 'add locks to deepest sub select in limit offset sql that has a limited tally' do
      options = { :limit => 3, :offset => 5, :lock => 'WITH (NOLOCK)' }
      select_sql = 'SELECT * FROM books'
      expected_sql = "SELECT * FROM (SELECT TOP 3 * FROM (SELECT TOP 8 * FROM books WITH (NOLOCK)) AS tmp1) AS tmp2"
      @connection.add_limit_offset! select_sql, options
      assert_equal expected_sql, @connection.add_lock!(select_sql,options)
    end
    
    should_eventually 'not create invalid SQL with subquery SELECTs with TOP' do
      options = { :limit => 5, :offset => 1 }
      subquery_select_sql = 'SELECT *, (SELECT TOP (1) [id] FROM [books]) AS [book_id] FROM [books]'
      expected_sql = "SELECT * FROM (SELECT TOP 5 * FROM (SELECT TOP 6 *, (SELECT TOP 1 id FROM books) AS book_id FROM books) AS tmp1) AS tmp2"
      assert_equal expected_sql, @connection.add_limit_offset!(subquery_select_sql,options)
    end
    
  end
  
  
  protected
  
  def create_10_books
    @books = (1..10).map {|i| Book.create!}
  end
  
  def destroy_all_books
    @books.each { |b| b.destroy }
  end
  
end

