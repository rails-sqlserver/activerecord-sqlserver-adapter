require "cases/sqlserver_helper"
require 'models/post'


class RelationTest < ActiveRecord::TestCase
  COERCED_TESTS = [
    :test_merging_reorders_bind_params,
    :test_to_sql_on_eager_join
  ]
  # Until that patch is made to rails we are preventing this test from running in this gem.
  include SqlserverCoercedTest
  fixtures :posts

  def test_coerced_merging_reorders_bind_params
    post         = Post.first
    id_column    = Post.columns_hash['id']
    title_column = Post.columns_hash['title']

    bvr = Post.connection.substitute_at id_column, 1
    right  = Post.where(id: bvr)
    right.bind_values += [[id_column, post.id]]

    bvl = Post.connection.substitute_at title_column, 0
    left   = Post.where(title: bvl)
    left.bind_values += [[title_column, post.title]]

    merged = left.merge(right)
    assert_equal post, merged.first
  end

  def test_coerced_to_sql_on_eager_join
    expected = assert_sql {
      Post.eager_load(:last_comment).order('comments.id DESC').to_a
    }.first
    actual = Post.eager_load(:last_comment).order('comments.id DESC').to_sql
    assert_equal expected.include?(actual), true
  end
end
