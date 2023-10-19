# frozen_string_literal: true

require "cases/helper_sqlserver"

class TestDisconnectedAdapter < ActiveRecord::TestCase
  self.use_transactional_tests = false

  undef_method :setup
  def setup
    @connection = ActiveRecord::Base.connection
  end

  teardown do
    return if in_memory_db?
    db_config = ActiveRecord::Base.connection_db_config
    ActiveRecord::Base.establish_connection(db_config)
  end

  test "execute procedure after disconnect reconnects" do
    @connection.execute_procedure :sp_tables, "sst_datatypes"
    @connection.disconnect!
    @connection.execute_procedure :sp_tables, "sst_datatypes"
  end

  test "execute query after disconnect reconnects" do
    sql = "SELECT count(*) from products WHERE id IN(@0, @1)"
    binds = [
      ActiveRecord::Relation::QueryAttribute.new("id", 2, ActiveRecord::Type::BigInteger.new),
      ActiveRecord::Relation::QueryAttribute.new("id", 2, ActiveRecord::Type::BigInteger.new)
    ]

    @connection.exec_query sql, "TEST", binds
    @connection.disconnect!
    @connection.exec_query sql, "TEST", binds
  end
end
