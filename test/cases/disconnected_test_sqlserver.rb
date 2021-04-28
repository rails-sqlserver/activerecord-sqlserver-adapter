# frozen_string_literal: true

require "cases/helper_sqlserver"

class TestDisconnectedAdapter < ActiveRecord::TestCase
  self.use_transactional_tests = false

  def setup
    @connection = ActiveRecord::Base.connection
  end

  teardown do
    return if in_memory_db?
    db_config = ActiveRecord::Base.connection_db_config
    ActiveRecord::Base.establish_connection(db_config)
  end

  test "can't execute procedures while disconnected" do
    @connection.execute_procedure :sp_tables, "sst_datatypes"
    @connection.disconnect!
    assert_raises(ActiveRecord::ConnectionNotEstablished, 'SQL Server client is not connected') do
      @connection.execute_procedure :sp_tables, "sst_datatypes"
    end
  end

  test "can't execute query while disconnected" do
    sql = "SELECT count(*) from products WHERE id IN(@0, @1)"
    binds = [
      ActiveRecord::Relation::QueryAttribute.new("id", 2, ActiveRecord::Type::BigInteger.new),
      ActiveRecord::Relation::QueryAttribute.new("id", 2, ActiveRecord::Type::BigInteger.new)
    ]

    @connection.exec_query sql, "TEST", binds
    @connection.disconnect!
    assert_raises(ActiveRecord::ConnectionNotEstablished, 'SQL Server client is not connected') do
      @connection.exec_query sql, "TEST", binds
    end
  end
end
