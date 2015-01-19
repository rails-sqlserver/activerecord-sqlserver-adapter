require 'cases/helper_sqlserver'
require 'models/post'

class OrderTestSQLServer < ActiveRecord::TestCase

  fixtures :posts

  it 'not mangel complex order clauses' do
    xyz_order = "CASE WHEN [title] LIKE N'XYZ%' THEN 0 ELSE 1 END"
    xyz_post = Post.create title: 'XYZ Post', body: 'Test cased orders.'
    assert_equal xyz_post, Post.order(Arel.sql(xyz_order)).first
  end

  it 'support column' do
    order = "title"
    post1 = Post.create title: 'AAA Post', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
  end

  it 'support column ASC' do
    order = "title ASC"
    post1 = Post.create title: 'AAA Post', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
  end

  it 'support column DESC' do
    order = "title DESC"
    post1 = Post.create title: 'ZZZ Post', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
  end

  it 'support column as symbol' do
    order = :title
    post1 = Post.create title: 'AAA Post', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
  end

  it 'support table and column' do
    order = "posts.title"
    post1 = Post.create title: 'AAA Post', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
  end

  it 'support quoted column' do
    order = "[title]"
    post1 = Post.create title: 'AAA Post', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
  end

  it 'support quoted table and column' do
    order = "[posts].[title]"
    post1 = Post.create title: 'AAA Post', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
  end

  it 'support primary: column, secondary: column' do
    order = "title DESC, body"
    post1 = Post.create title: 'ZZZ Post', body: 'Test cased orders.'
    post2 = Post.create title: 'ZZZ Post', body: 'ZZZ Test cased orders.'
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end

  it 'support primary: table and column, secondary: column' do
    order = "posts.title DESC, body"
    post1 = Post.create title: 'ZZZ Post', body: 'Test cased orders.'
    post2 = Post.create title: 'ZZZ Post', body: 'ZZZ Test cased orders.'
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end

  it 'support primary: case expression, secondary: column' do
    order = "(CASE WHEN [title] LIKE N'ZZZ%' THEN title ELSE '' END) DESC, body"
    post1 = Post.create title: 'ZZZ Post', body: 'Test cased orders.'
    post2 = Post.create title: 'ZZZ Post', body: 'ZZZ Test cased orders.'
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end

  it 'support primary: quoted table and column, secondary: case expresion' do
    order = "[posts].[body] DESC, (CASE WHEN [title] LIKE N'ZZZ%' THEN title ELSE '' END) DESC"
    post1 = Post.create title: 'ZZZ Post', body: 'ZZZ Test cased orders.'
    post2 = Post.create title: 'ZZY Post', body: 'ZZZ Test cased orders.'
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end

  it 'support inline function' do
    order = "LEN(title)"
    post1 = Post.create title: 'A', body: 'AAA Test cased orders.'
    assert_equal post1, Post.order(order).first
  end

  it 'support inline function with parameters' do
    order = "SUBSTRING(title, 1, 3)"
    post1 = Post.create title: 'AAA Post', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
  end

  it 'support inline function with parameters DESC' do
    order = "SUBSTRING(title, 1, 3) DESC"
    post1 = Post.create title: 'ZZZ Post', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
  end

  it 'support primary: inline function, secondary: column' do
    order = "LEN(title), body"
    post1 = Post.create title: 'A', body: 'AAA Test cased orders.'
    post2 = Post.create title: 'A', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end

  it 'support primary: inline function, secondary: column with direction' do
    order = "LEN(title) ASC, body DESC"
    post1 = Post.create title: 'A', body: 'ZZZ Test cased orders.'
    post2 = Post.create title: 'A', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end

  it 'support primary: column, secondary: inline function' do
    order = "body DESC, LEN(title)"
    post1 = Post.create title: 'Post', body: 'ZZZ Test cased orders.'
    post2 = Post.create title: 'Longer Post', body: 'ZZZ Test cased orders.'
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end

  it 'support primary: case expression, secondary: inline function' do
    order = "CASE WHEN [title] LIKE N'ZZZ%' THEN title ELSE '' END DESC, LEN(body) ASC"
    post1 = Post.create title: 'ZZZ Post', body: 'Z'
    post2 = Post.create title: 'ZZZ Post', body: 'Test cased orders.'
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end

  it 'support primary: inline function, secondary: case expression' do
    order = "LEN(body), CASE WHEN [title] LIKE N'ZZZ%' THEN title ELSE '' END DESC"
    post1 = Post.create title: 'ZZZ Post', body: 'Z'
    post2 = Post.create title: 'Post', body: 'Z'
    assert_equal post1, Post.order(order).first
    assert_equal post2, Post.order(order).second
  end


end
