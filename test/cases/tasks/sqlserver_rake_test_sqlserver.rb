require 'cases/helper'
require(Dir.pwd + '/lib/active_record/tasks/sqlserver_database_tasks.rb')

module ActiveRecord
  class SQLServerDropTest < ActiveRecord::TestCase
    def setup
      @connection    = stub(:drop_database => true)
      @configuration = {
        'adapter'  => 'sqlserver',
        'database' => 'activerecord_unittest'
      }

      ActiveRecord::Base.stubs(:connection).returns(@connection)
      ActiveRecord::Base.stubs(:establish_connection).returns(true)
      ActiveRecord::Tasks::DatabaseTasks.register_task(/sqlserver/, ActiveRecord::Tasks::SQLServerDatabaseTasks)
    end

    def test_establishes_connection_to_sqlserver_database
      ActiveRecord::Base.expects(:establish_connection).with @configuration

      ActiveRecord::Tasks::DatabaseTasks.drop @configuration
    end

    def test_drops_database
      @connection.expects(:drop_database).with('activerecord_unittest')

      ActiveRecord::Tasks::DatabaseTasks.drop @configuration
    end
  end

  class SQLServerPurgeTest < ActiveRecord::TestCase
    def setup
      @connection    = stub(:recreate_database => true)
      @configuration = {
        'adapter'  => 'sqlserver',
        'database' => 'activerecord_unittest'
      }

      ActiveRecord::Base.stubs(:connection).returns(@connection)
      ActiveRecord::Base.stubs(:establish_connection).returns(true)
      ActiveRecord::Tasks::DatabaseTasks.register_task(/sqlserver/, ActiveRecord::Tasks::SQLServerDatabaseTasks)
    end

    def test_establishes_connection_to_test_database
      ActiveRecord::Base.expects(:establish_connection).with(@configuration)

      ActiveRecord::Tasks::DatabaseTasks.purge @configuration
    end

    def test_recreates_database
      @connection.expects(:recreate_database)

      ActiveRecord::Tasks::DatabaseTasks.purge @configuration
    end

  end

end
