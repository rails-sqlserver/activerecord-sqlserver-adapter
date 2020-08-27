# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/post"
require "models/author"

class LateralTestSQLServer < ActiveRecord::TestCase
  fixtures :posts, :authors

  it 'uses OUTER APPLY for OUTER JOIN LATERAL' do
    post = Arel::Table.new(:posts)
    author = Arel::Table.new(:authors)
    subselect = post.project(Arel.star).take(1).where(post[:author_id].eq(author[:id])).where(post[:id].eq(42))

    one = Arel::Nodes::Quoted.new(1)
    eq = Arel::Nodes::Equality.new(one, one)

    sql = author.project(Arel.star).where(author[:name].matches("David")).outer_join(subselect.lateral.as("bar")).on(eq).to_sql
    results = ActiveRecord::Base.connection.exec_query sql
    assert_equal sql, "SELECT * FROM [authors] OUTER APPLY (SELECT * FROM [posts] WHERE [posts].[author_id] = [authors].[id] AND [posts].[id] = 42 ORDER BY [posts].[id] ASC OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY) AS bar WHERE [authors].[name] LIKE N'David'"
    assert_equal results.length, 1
  end

  it 'uses CROSS APPLY for INNER JOIN LATERAL' do
    post = Arel::Table.new(:posts)
    author = Arel::Table.new(:authors)
    subselect = post.project(Arel.star).take(1).where(post[:author_id].eq(author[:id])).where(post[:id].eq(42))

    sql = author.project(Arel.star).where(author[:name].matches("David")).join(subselect.lateral.as("bar")).to_sql
    results = ActiveRecord::Base.connection.exec_query sql

    assert_equal sql, "SELECT * FROM [authors] CROSS APPLY (SELECT * FROM [posts] WHERE [posts].[author_id] = [authors].[id] AND [posts].[id] = 42 ORDER BY [posts].[id] ASC OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY) AS bar WHERE [authors].[name] LIKE N'David'"
    assert_equal results.length, 0
  end
end
