# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/post"
require "models/author"

class InClauseTestSQLServer < ActiveRecord::TestCase
  fixtures :posts, :authors

  it "removes ordering from subqueries" do
    authors_subquery = Author.where(name: ["David", "Mary", "Bob"]).order(:name)
    posts = Post.where(author: authors_subquery)

    assert_includes authors_subquery.to_sql, "ORDER BY [authors].[name]"
    assert_not_includes posts.to_sql, "ORDER BY [authors].[name]"
    assert_equal 10, posts.length
  end

  it "does not remove ordering from subquery that includes a limit" do
    authors_subquery = Author.where(name: ["David", "Mary", "Bob"]).order(:name).limit(2)
    posts = Post.where(author: authors_subquery)

    assert_includes authors_subquery.to_sql, "ORDER BY [authors].[name]"
    assert_includes posts.to_sql, "ORDER BY [authors].[name]"
    assert_equal 7, posts.length
  end

  it "does not remove ordering from subquery that includes an offset" do
    authors_subquery = Author.where(name: ["David", "Mary", "Bob"]).order(:name).offset(1)
    posts = Post.where(author: authors_subquery)

    assert_includes authors_subquery.to_sql, "ORDER BY [authors].[name]"
    assert_includes posts.to_sql, "ORDER BY [authors].[name]"
    assert_equal 8, posts.length
  end
end
