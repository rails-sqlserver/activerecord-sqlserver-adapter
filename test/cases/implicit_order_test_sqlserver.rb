# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/post"
require "models/company"

class ImplicitOrderTestSQLServer < ActiveRecord::TestCase


  describe "GROUP queries" do

    it "order by primary key if not a GROUP query" do
      assert_queries_match(/#{Regexp.escape("ORDER BY [posts].[id] ASC")}/i) do
        Post.pick(:title)
      end
    end

    it "ordering not required if not using FETCH" do
      assert_queries_match(/^#{Regexp.escape("SELECT count(*) FROM [posts] GROUP BY [posts].[title]")}$/i) do
        Post.group(:title).select("count(*)").load
      end
    end

    it "error if using `first` without primary key projection (as `find_nth_with_limit` adds primary key ordering)" do
      error = assert_raises(ActiveRecord::StatementInvalid) do
        Post.select(:title, "count(*)").group(:title).first(2)
      end
      assert_match(/Column "posts\.id" is invalid in the ORDER BY clause/, error.message)
    end


    it "using `first` with primary key projection (as `find_nth_with_limit` adds primary key ordering)" do
      assert_queries_match(/#{Regexp.escape("SELECT [posts].[title], count(*) FROM [posts] GROUP BY [posts].[title] ORDER BY [posts].[title]")}/i) do
        Post.select(:title, "count(*)").group(:title).order(:title).first(2)
      end
    end
  end



  # describe "simple query containing limit" do
  #   it "order by primary key if no projections" do
  #     sql = Post.limit(5).to_sql
  #
  #     assert_equal "SELECT [posts].* FROM [posts] ORDER BY [posts].[id] ASC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY", sql
  #   end
  #
  #   it "use order provided" do
  #     sql = Post.select(:legacy_comments_count).order(:tags_count).limit(5).to_sql
  #
  #     assert_equal "SELECT [posts].[legacy_comments_count] FROM [posts] ORDER BY [posts].[tags_count] ASC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY", sql
  #   end
  #
  # end
  #
  # describe "query containing FROM and limit" do
  #   it "uses the provided orderings" do
  #     sql = "SELECT sum(legacy_comments_count), count(*), min(legacy_comments_count) FROM (SELECT [posts].[legacy_comments_count] FROM [posts] ORDER BY [posts].[legacy_comments_count] DESC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY) subquery ORDER BY sum(legacy_comments_count) ASC OFFSET 0 ROWS FETCH NEXT @1 ROWS ONLY"
  #
  #     assert_queries_match(/#{Regexp.escape(sql)}/) do
  #       result = Post.from(Post.order(legacy_comments_count: :desc).limit(5).select(:legacy_comments_count)).pick(Arel.sql("sum(legacy_comments_count), count(*), min(legacy_comments_count)"))
  #       assert_equal result, [11, 5, 1]
  #     end
  #   end
  #
  #   it "in the subquery the first projection is used for ordering if none provided" do
  #     sql = "SELECT sum(legacy_comments_count), count(*), min(legacy_comments_count) FROM (SELECT [posts].[legacy_comments_count], [posts].[tags_count] FROM [posts] ORDER BY [posts].[id] ASC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY) subquery ORDER BY sum(legacy_comments_count) ASC OFFSET 0 ROWS FETCH NEXT @1 ROWS ONLY"
  #
  #     # $DEBUG = true
  #
  #     assert_queries_match(/#{Regexp.escape(sql)}/) do
  #       result = Post.from(Post.limit(5).select(:legacy_comments_count, :tags_count)).pick(Arel.sql("sum(legacy_comments_count), count(*), min(legacy_comments_count)"))
  #       assert_equal result, [10, 5, 0]
  #     end
  #   end
  #
  #   it "in the subquery the primary key is used for ordering if none provided" do
  #     sql = "SELECT sum(legacy_comments_count), count(*), min(legacy_comments_count) FROM (SELECT [posts].* FROM [posts] ORDER BY [posts].[id] ASC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY) subquery ORDER BY sum(legacy_comments_count) ASC OFFSET 0 ROWS FETCH NEXT @1 ROWS ONLY"
  #
  #     assert_queries_match(/#{Regexp.escape(sql)}/) do
  #       result = Post.from(Post.limit(5)).pick(Arel.sql("sum(legacy_comments_count), count(*), min(legacy_comments_count)"))
  #       assert_equal result, [10, 5, 0]
  #     end
  #   end
  # end
  #
  #
  # it "generates correct SQL" do
  #
  #   # $DEBUG = true
  #
  #   sql = "SELECT [posts].[title], [posts].[id] FROM [posts] ORDER BY [posts].[id] ASC"
  #
  #   assert_queries_match(/#{Regexp.escape(sql)}/) do
  #     Post.select(posts: [:title, :id]).take
  #   end
  #
  #   # assert_match /#{Regexp.escape(sql)}/, Post.select(posts: [:bar, :id]).to_sql
  #
  # end

end
