require 'cases/sqlserver_helper'

class SchemaStatementTestSqlserver < ActiveRecord::TestCase

  def setup
    @connection = ActiveRecord::Base.connection
  end

  should 'create integers when no limit supplied' do
    assert_equal 'integer', @connection.type_to_sql(:integer)
  end

  should 'create integers when limit is 4' do
    assert_equal 'integer', @connection.type_to_sql(:integer, 4)
  end

  should 'create integers when limit is 3' do
    assert_equal 'integer', @connection.type_to_sql(:integer, 3)
  end

  should 'create smallints when limit is less than 3' do
    assert_equal 'smallint', @connection.type_to_sql(:integer, 2)
    assert_equal 'smallint', @connection.type_to_sql(:integer, 1)
  end

  should 'create bigints when limit is greateer than 4' do
    assert_equal 'bigint', @connection.type_to_sql(:integer, 5)
    assert_equal 'bigint', @connection.type_to_sql(:integer, 6)
    assert_equal 'bigint', @connection.type_to_sql(:integer, 7)
    assert_equal 'bigint', @connection.type_to_sql(:integer, 8)
  end
  
  
end
