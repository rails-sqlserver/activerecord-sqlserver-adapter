# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/post"

class OrderTestSQLServer < ActiveRecord::TestCase
  fixtures :posts

  it "not mangel complex order clauses" do
    xyz_order = "CASE WHEN [title] LIKE N'XYZ%' THEN 0 ELSE 1 END"
    xyz_post = Post.create title: "XYZ Post", body: "Test cased orders."
    assert_equal xyz_post, Post.order(Arel.sql(xyz_order)).first
  end

  it "support column" do
    order = "title"
    post1 = Post.create title: "AAA Post", body: "Test cased orders."
    assert_equal post1, Post.order(order).first
  end

  it "support column ASC" do
    order = "title ASC"
    post1 = Post.create title: "AAA Post", body: "Test cased orders."
    assert_equal post1, Post.order(order).first
  end

  it "support column DESC" do
    order = "title DESC"
    post1 = Post.create title: "ZZZ Post", body: "Test cased orders."
    assert_equal post1, Post.order(order).first
  end

  it "support column as symbol" do
    order = :title
    post1 = Post.create title: "AAA Post", body: "Test cased orders."
    assert_equal post1, Post.order(order).first
  end

  it "support table and column" do
    order = "posts.title"
    post1 = Post.create title: "AAA Post", body: "Test cased orders."
    assert_equal post1, Post.order(order).first
  end

  it "support quoted column" do
    order = "[title]"
    post1 = Post.create title: "AAA Post", body: "Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
  end

  it "support quoted table and column" do
    order = "[posts].[title]"
    post1 = Post.create title: "AAA Post", body: "Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
  end

  it "support primary: column, secondary: column" do
    order = "title DESC, body"
    post1 = Post.create title: "ZZZ Post", body: "Test cased orders."
    post2 = Post.create title: "ZZZ Post", body: "ZZZ Test cased orders."
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end

  it "support primary: table and column, secondary: column" do
    order = "posts.title DESC, body"
    post1 = Post.create title: "ZZZ Post", body: "Test cased orders."
    post2 = Post.create title: "ZZZ Post", body: "ZZZ Test cased orders."
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end

  it "support primary: case expression, secondary: column" do
    order = "(CASE WHEN [title] LIKE N'ZZZ%' THEN title ELSE '' END) DESC, body"
    post1 = Post.create title: "ZZZ Post", body: "Test cased orders."
    post2 = Post.create title: "ZZZ Post", body: "ZZZ Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
    assert_equal post2, Post.order(Arel.sql(order)).second
  end

  it "support primary: quoted table and column, secondary: case expresion" do
    order = "[posts].[body] DESC, (CASE WHEN [title] LIKE N'ZZZ%' THEN title ELSE '' END) DESC"
    post1 = Post.create title: "ZZZ Post", body: "ZZZ Test cased orders."
    post2 = Post.create title: "ZZY Post", body: "ZZZ Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
    assert_equal post2, Post.order(Arel.sql(order)).second
  end

  it "support inline function" do
    order = "LEN(title)"
    post1 = Post.create title: "A", body: "AAA Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
  end

  it "support inline function with parameters" do
    order = "SUBSTRING(title, 1, 3)"
    post1 = Post.create title: "AAA Post", body: "Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
  end

  it "support inline function with parameters DESC" do
    order = "SUBSTRING(title, 1, 3) DESC"
    post1 = Post.create title: "ZZZ Post", body: "Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
  end

  it "support primary: inline function, secondary: column" do
    order = "LEN(title), body"
    post1 = Post.create title: "A", body: "AAA Test cased orders."
    post2 = Post.create title: "A", body: "Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
    assert_equal post2, Post.order(Arel.sql(order)).second
  end

  it "support primary: inline function, secondary: column with direction" do
    order = "LEN(title) ASC, body DESC"
    post1 = Post.create title: "A", body: "ZZZ Test cased orders."
    post2 = Post.create title: "A", body: "Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
    assert_equal post2, Post.order(Arel.sql(order)).second
  end

  it "support primary: column, secondary: inline function" do
    order = "body DESC, LEN(title)"
    post1 = Post.create title: "Post", body: "ZZZ Test cased orders."
    post2 = Post.create title: "Longer Post", body: "ZZZ Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
    assert_equal post2, Post.order(Arel.sql(order)).second
  end

  it "support primary: case expression, secondary: inline function" do
    order = "CASE WHEN [title] LIKE N'ZZZ%' THEN title ELSE '' END DESC, LEN(body) ASC"
    post1 = Post.create title: "ZZZ Post", body: "Z"
    post2 = Post.create title: "ZZZ Post", body: "Test cased orders."
    assert_equal post1, Post.order(Arel.sql(order)).first
    assert_equal post2, Post.order(Arel.sql(order)).second
  end

  it "support primary: inline function, secondary: case expression" do
    order = "LEN(body), CASE WHEN [title] LIKE N'ZZZ%' THEN title ELSE '' END DESC"
    post1 = Post.create title: "ZZZ Post", body: "Z"
    post2 = Post.create title: "Post", body: "Z"
    assert_equal post1, Post.order(Arel.sql(order)).first
    assert_equal post2, Post.order(Arel.sql(order)).second
  end

  # Executing this kind of queries will raise "A column has been specified more than once in the order by list"
  # This test shows that we don't do anything to prevent this
  it "doesn't deduplicate semantically equal orders" do
    sql = Post.order(:id).order("posts.id ASC").to_sql
    assert_equal "SELECT [posts].* FROM [posts] ORDER BY [posts].[id] ASC, posts.id ASC", sql
  end

  describe "simple query containing limit" do
    it "order by primary key if no projections" do
      sql = Post.limit(5).to_sql

      assert_equal "SELECT [posts].* FROM [posts] ORDER BY [posts].[id] ASC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY", sql
    end

    it "use order provided" do
      sql = Post.select(:legacy_comments_count).order(:tags_count).limit(5).to_sql

      assert_equal "SELECT [posts].[legacy_comments_count] FROM [posts] ORDER BY [posts].[tags_count] ASC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY", sql
    end

    it "order by first projection if no order provided" do
      sql = Post.select(:legacy_comments_count).limit(5).to_sql

      assert_equal "SELECT [posts].[legacy_comments_count] FROM [posts] ORDER BY [posts].[legacy_comments_count] ASC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY", sql
    end

    it "order by first projection (when multiple projections) if no order provided" do
      sql = Post.select(:legacy_comments_count, :tags_count).limit(5).to_sql

      assert_equal "SELECT [posts].[legacy_comments_count], [posts].[tags_count] FROM [posts] ORDER BY [posts].[legacy_comments_count] ASC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY", sql
    end
  end

  describe "query containing FROM and limit" do
    it "uses the provided orderings" do
      sql = "SELECT sum(legacy_comments_count), count(*), min(legacy_comments_count) FROM (SELECT [posts].[legacy_comments_count] FROM [posts] ORDER BY [posts].[legacy_comments_count] DESC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY) subquery ORDER BY sum(legacy_comments_count) ASC OFFSET 0 ROWS FETCH NEXT @1 ROWS ONLY"

      assert_queries_match(/#{Regexp.escape(sql)}/) do
        result = Post.from(Post.order(legacy_comments_count: :desc).limit(5).select(:legacy_comments_count)).pick(Arel.sql("sum(legacy_comments_count), count(*), min(legacy_comments_count)"))
        assert_equal result, [11, 5, 1]
      end
    end

    it "in the subquery the first projection is used for ordering if none provided" do
      sql = "SELECT sum(legacy_comments_count), count(*), min(legacy_comments_count) FROM (SELECT [posts].[legacy_comments_count], [posts].[tags_count] FROM [posts] ORDER BY [posts].[legacy_comments_count] ASC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY) subquery ORDER BY sum(legacy_comments_count) ASC OFFSET 0 ROWS FETCH NEXT @1 ROWS ONLY"

      assert_queries_match(/#{Regexp.escape(sql)}/) do
        result = Post.from(Post.limit(5).select(:legacy_comments_count, :tags_count)).pick(Arel.sql("sum(legacy_comments_count), count(*), min(legacy_comments_count)"))
        assert_equal result, [0, 5, 0]
      end
    end

    it "in the subquery the primary key is used for ordering if none provided" do
      sql = "SELECT sum(legacy_comments_count), count(*), min(legacy_comments_count) FROM (SELECT [posts].* FROM [posts] ORDER BY [posts].[id] ASC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY) subquery ORDER BY sum(legacy_comments_count) ASC OFFSET 0 ROWS FETCH NEXT @1 ROWS ONLY"

      assert_queries_match(/#{Regexp.escape(sql)}/) do
        result = Post.from(Post.limit(5)).pick(Arel.sql("sum(legacy_comments_count), count(*), min(legacy_comments_count)"))
        assert_equal result, [10, 5, 0]
      end
    end
  end
end
