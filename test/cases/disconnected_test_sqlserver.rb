if Pathname.new("#{ACTIVERECORD_TEST_ROOT}/cases/disconnected_test.rb").exist?
  #cases/disconnected_test was added in rails 4.0.1 so this errors in 4.0.0
  require 'cases/sqlserver_helper'
  require 'cases/disconnected_test'

  class TestDisconnectedAdapter < ActiveRecord::TestCase
    def setup
      skip "TestDisconnectedAdapterSqlserver instead "
    end
  end

  class TestDisconnectedAdapterSqlserver < ActiveRecord::TestCase
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
end
