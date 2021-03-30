# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/post"

class OptimizerHintsTestSQLServer < ActiveRecord::TestCase
  fixtures :posts

  def test_optimizer_hints
    expected_sql = "SELECT [posts].* FROM [posts] OPTION (MAXDOP 2)"
    current_sql = Post.optimizer_hints("MAXDOP 2").to_sql
    assert_equal expected_sql, current_sql
  end

  def test_multiple_optimizer_hints
    expected_sql = "SELECT [posts].* FROM [posts] OPTION (MAXDOP 2, KEEPFIXED PLAN)"
    current_sql = Post.optimizer_hints("MAXDOP 2").optimizer_hints("KEEPFIXED PLAN").to_sql
    assert_equal expected_sql, current_sql
  end

  def test_optimizer_hints_with_count_subquery
    assert_sql(%r{.*'SELECT COUNT\(count_column\) FROM \(SELECT .*\) subquery_for_count OPTION \(MAXDOP 2\)'.*}) do
      posts = Post.optimizer_hints("MAXDOP 2")
      posts = posts.select(:id).where(author_id: [0, 1]).limit(5)
      assert_equal 5, posts.count
    end
  end

  def test_optimizer_hints_with_unscope
    expected_sql = "SELECT [posts].* FROM [posts]"
    current_sql = Post.optimizer_hints("MAXDOP 2").unscope(:optimizer_hints).to_sql
    assert_equal expected_sql, current_sql
  end
end
