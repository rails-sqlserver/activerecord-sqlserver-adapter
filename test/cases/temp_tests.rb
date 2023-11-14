# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/author"

class TempTestSQLServer < ActiveRecord::TestCase
  fixtures :topics, :authors, :author_addresses, :posts

  def test_bind_params_to_sql_with_prepared_statements_coerced
    assert_bind_params_to_sql_coerced(prepared: true)
  end

  # def test_bind_params_to_sql_with_unprepared_statements_coerced
  #   connection.unprepared_statement do
  #     assert_bind_params_to_sql_coerced(prepared: false)
  #   end
  # end

  def assert_bind_params_to_sql_coerced(prepared:)
    @connection = connection


    table = Author.quoted_table_name
    pk = "#{table}.#{Author.quoted_primary_key}"

    # $DEBUG = true

    # prepared_statements: true
    #
    #   EXEC sp_executesql N'SELECT [authors].* FROM [authors] WHERE [authors].[id] IN (@0, @1, @2) OR [authors].[id] IS NULL)', N'@0 bigint, @1 bigint, @2 bigint', @0 = 1, @1 = 2, @2 = 3
    #
    # prepared_statements: false
    #
    #   SELECT [authors].* FROM [authors] WHERE ([authors].[id] IN (1, 2, 3) OR [authors].[id] IS NULL)
    #
    sql_unprepared = "SELECT #{table}.* FROM #{table} WHERE (#{pk} IN (#{bind_params(1..3)}) OR #{pk} IS NULL)"
    sql_prepared = "EXEC sp_executesql N'SELECT #{table}.* FROM #{table} WHERE (#{pk} IN (#{bind_params(1..3)}) OR #{pk} IS NULL)', N'@0 bigint, @1 bigint, @2 bigint', @0 = 1, @1 = 2, @2 = 3"

    authors = Author.where(id: [1, 2, 3, nil])
    assert_equal sql_unprepared, @connection.to_sql(authors.arel)
    assert_sql(prepared ? sql_prepared : sql_unprepared) { assert_equal 3, authors.length }

    # prepared_statements: true
    #
    #   EXEC sp_executesql N'SELECT [authors].* FROM [authors] WHERE [authors].[id] IN (@0, @1, @2)', N'@0 bigint, @1 bigint, @2 bigint', @0 = 1, @1 = 2, @2 = 3
    #
    # prepared_statements: false
    #
    #   SELECT [authors].* FROM [authors] WHERE [authors].[id] IN (1, 2, 3)
    #
    sql_unprepared = "SELECT #{table}.* FROM #{table} WHERE #{pk} IN (#{bind_params(1..3)})"
    sql_prepared = "EXEC sp_executesql N'SELECT #{table}.* FROM #{table} WHERE #{pk} IN (#{bind_params(1..3)})', N'@0 bigint, @1 bigint, @2 bigint', @0 = 1, @1 = 2, @2 = 3"

    authors = Author.where(id: [1, 2, 3, 9223372036854775808])
    assert_equal sql_unprepared, @connection.to_sql(authors.arel)
    assert_sql(prepared ? sql_prepared : sql_unprepared) { assert_equal 3, authors.length }
  end

  def bind_params(ids)
    collector = connection.send(:collector)
    bind_params = ids.map { |i| Arel::Nodes::BindParam.new(i) }

    # binding.pry

    # Author.columns

    puts "bind_params: #{bind_params.inspect}"

    sql, _ = connection.visitor.compile(bind_params, collector)
    sql
  end




end
