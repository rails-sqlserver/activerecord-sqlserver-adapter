require 'cases/sqlserver_helper'

class SchemaStatementTestSqlserver < ActiveRecord::TestCase

  def setup
    @connection = ActiveRecord::Base.connection
  end

  def test_should_create_integers_when_no_limit_supplied
    assert_equal 'integer', @connection.type_to_sql(:integer)
  end

  def test_should_create_integers_when_limit_is_4
    assert_equal 'integer', @connection.type_to_sql(:integer, 4)
  end

  def test_should_create_integers_when_limit_is_3
    assert_equal 'integer', @connection.type_to_sql(:integer, 3)
  end

  def test_should_create_smallints_when_limit_is_less_than_3
    assert_equal 'smallint', @connection.type_to_sql(:integer, 2)
    assert_equal 'smallint', @connection.type_to_sql(:integer, 1)
  end

  def test_should_create_bigints_when_limit_is_greateer_than_4
    assert_equal 'bigint', @connection.type_to_sql(:integer, 5)
    assert_equal 'bigint', @connection.type_to_sql(:integer, 6)
    assert_equal 'bigint', @connection.type_to_sql(:integer, 7)
    assert_equal 'bigint', @connection.type_to_sql(:integer, 8)
  end

end
