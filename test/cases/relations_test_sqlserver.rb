require "cases/sqlserver_helper"
require 'models/post'


class RelationTest < ActiveRecord::TestCase
  COERCED_TESTS = [:test_merging_reorders_bind_params] 
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
end