require 'cases/sqlserver_helper'
require 'models/job'
require 'models/person'
require 'models/reference'
require 'models/book'
require 'models/author'
require 'models/subscription'
require 'models/post'
require 'models/comment'
require 'models/categorization'
require 'models_sqlserver/sql_server_order_row_number'

class OffsetAndLimitTestSqlserver < ActiveRecord::TestCase

  fixtures :jobs, :people, :references, :subscriptions,
           :authors, :posts, :comments, :categorizations

  setup     :create_10_books
  teardown  :destroy_all_books


  context 'When selecting with limit' do

    should 'alter sql to limit number of records returned' do
      assert_sql(/SELECT TOP \(10\)/) { Book.limit(10).load }
    end

  end

  context 'When selecting with offset' do

    should 'have limit (top) of 9223372036854775807 if only offset is passed' do
      assert_sql(/SELECT TOP \(9223372036854775807\) \[__rnt\]\.\* FROM.*WHERE \[__rnt\]\.\[__rn\] > \(1\)/) { Book.offset(1).load }
    end

    should 'support calling exists?' do
      assert Book.offset(3).exists?
    end

  end

  context 'When selecting with limit and offset' do

    should 'work with fully qualified table and columns in select' do
      books = Book.select('books.id, books.name').limit(3).offset(5)
      assert_equal Book.all[5,3].map(&:id), books.map(&:id)
    end

    should 'alter SQL to limit number of records returned offset by specified amount' do
      sql = %|EXEC sp_executesql N'SELECT TOP (3) [__rnt].* FROM ( SELECT ROW_NUMBER() OVER (ORDER BY [books].[id] ASC) AS [__rn], [books].* FROM [books] ) AS [__rnt] WHERE [__rnt].[__rn] > (5) ORDER BY [__rnt].[__rn] ASC'|
      assert_sql(sql) { Book.limit(3).offset(5).load }
    end

    should 'add locks to deepest sub select' do
      pattern = /FROM \[books\]\s+WITH \(NOLOCK\)/
      assert_sql(pattern) { Book.limit(3).lock('WITH (NOLOCK)').offset(5).count }
      assert_sql(pattern) { Book.limit(3).lock('WITH (NOLOCK)').offset(5).load }

    end

    should 'have valid sort order' do
      order_row_numbers = SqlServerOrderRowNumber.offset(7).order("c DESC").select("c, ROW_NUMBER() OVER (ORDER BY c ASC) AS [dummy]").map(&:c)
      assert_equal [2, 1, 0], order_row_numbers
    end

    should 'work with through associations' do
      assert_equal people(:david), jobs(:unicyclist).people.limit(1).offset(1).first
    end

    should 'work with through uniq associations' do
      david = authors(:david)
      mary = authors(:mary)
      thinking = posts(:thinking)
      # Mary has duplicate categorizations to the thinking post.
      assert_equal [thinking, thinking], mary.categorized_posts.load
      assert_equal [thinking], mary.unique_categorized_posts.limit(2).offset(0).load
      # Paging thru David's uniq ordered comments, with count too.
      assert_equal [1, 2, 3, 5, 6, 7, 8, 9, 10, 12], david.ordered_uniq_comments.map(&:id)
      assert_equal [3, 5], david.ordered_uniq_comments.limit(2).offset(2).map(&:id)
      assert_equal 2, david.ordered_uniq_comments.limit(2).offset(2).count
      assert_equal [8, 9, 10, 12], david.ordered_uniq_comments.limit(5).offset(6).map(&:id)
      assert_equal 4, david.ordered_uniq_comments.limit(5).offset(6).count
    end

    should 'remove [__rnt] table names from relation reflection and hence do not eager loading' do
      create_10_books
      create_10_books
      assert_queries(1) { Book.includes(:subscriptions).limit(10).offset(10).references(:subscriptions).load }
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

