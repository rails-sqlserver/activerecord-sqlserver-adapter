require 'cases/helper_sqlserver'
require 'cases/disconnected_test'

class TestDisconnectedAdapter < ActiveRecord::TestCase
  def setup
    skip "TestDisconnectedAdapterSQLServer instead "
  end
end

class TestDisconnectedAdapterSQLServer < ActiveRecord::TestCase
  self.use_transactional_fixtures = false

  def setup
    skip "in-memory database mustn't disconnect" if in_memory_db?
    @connection = ActiveRecord::Base.connection
  end

  def teardown
    return if in_memory_db?
    spec = ActiveRecord::Base.connection_config
    ActiveRecord::Base.establish_connection(spec)
  end

  test "can't execute statements while disconnected" do
    with_auto_connect(false) do
      @connection.execute "SELECT count(*) from products"
      @connection.disconnect!
      assert_raises(ActiveRecord::LostConnection) do
        @connection.execute "SELECT count(*) from products"
      end
    end
  end

end
