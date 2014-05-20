require 'cases/sqlserver_helper'
require 'active_record/tasks/sqlserver_database_tasks'

class SQLServerDBCreateTest < ActiveRecord::TestCase
  def setup
    @connection    = stub(create_database: true)
    @configuration = {
      'adapter'  => 'sqlserver',
      'database' => 'my-app-db'
    }

    ActiveRecord::Base.stubs(:connection).returns(@connection)
    ActiveRecord::Base.stubs(:establish_connection).returns(true)
  end

  def test_establishes_connection_to_master_database
    ActiveRecord::Base.expects(:establish_connection).with(
      'adapter'            => 'sqlserver',
      'database'           => 'master',
    )

    ActiveRecord::Tasks::DatabaseTasks.create @configuration
  end

  def test_creates_database_with_default_collation
    @connection.expects(:create_database).
      with('my-app-db', 'SQL_Latin1_General_CP1_CI_AS')

    ActiveRecord::Tasks::DatabaseTasks.create @configuration
  end

  def test_creates_database_with_given_collation
    @connection.expects(:create_database).
      with('my-app-db', 'Greek_BIN')

    ActiveRecord::Tasks::DatabaseTasks.create @configuration.
      merge('collation' => 'Greek_BIN')
  end

  def test_establishes_connection_to_new_database
    ActiveRecord::Base.expects(:establish_connection).with(@configuration)

    ActiveRecord::Tasks::DatabaseTasks.create @configuration
  end

  def test_db_create_with_error_prints_message
    ActiveRecord::Base.stubs(:establish_connection).raises(Exception)

    $stderr.stubs(:puts).returns(true)
    $stderr.expects(:puts).
      with("Couldn't create database for #{@configuration.inspect}")

    ActiveRecord::Tasks::DatabaseTasks.create @configuration
  end

  def test_create_when_database_exists_outputs_info_to_stderr
    $stderr.expects(:puts).with("my-app-db already exists").once

    ActiveRecord::Base.connection.stubs(:create_database).raises(
      ActiveRecord::StatementInvalid.new('database "my-app-db" already exists')
    )

    ActiveRecord::Tasks::DatabaseTasks.create @configuration
  end
end

class SQLServerDBDropTest < ActiveRecord::TestCase
  def setup
    @connection    = stub(drop_database: true)
    @configuration = {
      'adapter'  => 'sqlserver',
      'database' => 'my-app-db'
    }

    ActiveRecord::Base.stubs(:connection).returns(@connection)
    ActiveRecord::Base.stubs(:establish_connection).returns(true)
  end

  def test_establishes_connection_to_master_database
    ActiveRecord::Base.expects(:establish_connection).with(
      'adapter'            => 'sqlserver',
      'database'           => 'master',
    )

    ActiveRecord::Tasks::DatabaseTasks.drop @configuration
  end

  def test_drops_database
    @connection.expects(:drop_database).with('my-app-db')

    ActiveRecord::Tasks::DatabaseTasks.drop @configuration
  end
end

class SQLServerPurgeTest < ActiveRecord::TestCase
  def setup
    @connection    = stub(create_database: true, drop_database: true)
    @configuration = {
      'adapter'  => 'sqlserver',
      'database' => 'my-app-db'
    }

    ActiveRecord::Base.stubs(:connection).returns(@connection)
    ActiveRecord::Base.stubs(:clear_active_connections!).returns(true)
    ActiveRecord::Base.stubs(:establish_connection).returns(true)
  end

  def test_clears_active_connections
    ActiveRecord::Base.expects(:clear_active_connections!)

    ActiveRecord::Tasks::DatabaseTasks.purge @configuration
  end

  def test_establishes_connection_to_master_database
    ActiveRecord::Base.expects(:establish_connection).with(
      'adapter'            => 'sqlserver',
      'database'           => 'master',
    )

    ActiveRecord::Tasks::DatabaseTasks.purge @configuration
  end

  def test_drops_database
    @connection.expects(:drop_database).with('my-app-db')

    ActiveRecord::Tasks::DatabaseTasks.purge @configuration
  end

  def test_creates_database
    @connection.expects(:create_database).
      with('my-app-db', 'SQL_Latin1_General_CP1_CI_AS')

    ActiveRecord::Tasks::DatabaseTasks.purge @configuration
  end

  def test_establishes_connection
    ActiveRecord::Base.expects(:establish_connection).with(@configuration)

    ActiveRecord::Tasks::DatabaseTasks.purge @configuration
  end
end

class SQLServerDBCharsetTest < ActiveRecord::TestCase
  def setup
    @connection    = stub(create_database: true)
    @configuration = {
      'adapter'  => 'sqlserver',
      'database' => 'my-app-db'
    }

    ActiveRecord::Base.stubs(:connection).returns(@connection)
    ActiveRecord::Base.stubs(:establish_connection).returns(true)
  end

  def test_db_retrieves_charset
    @connection.expects(:charset)
    ActiveRecord::Tasks::DatabaseTasks.charset @configuration
  end
end

class SQLServerDBCollationTest < ActiveRecord::TestCase
  def setup
    @connection    = stub(create_database: true)
    @configuration = {
      'adapter'  => 'sqlserver',
      'database' => 'my-app-db'
    }

    ActiveRecord::Base.stubs(:connection).returns(@connection)
    ActiveRecord::Base.stubs(:establish_connection).returns(true)
  end

  def test_db_retrieves_collation
    @connection.expects(:collation)
    ActiveRecord::Tasks::DatabaseTasks.collation @configuration
  end
end

class SQLServerStructureDumpTest < ActiveRecord::TestCase
  def setup
    @connection    = stub(tables: ['a_table'], views: ['a_view'])
    @configuration = {
      'adapter'  => 'sqlserver',
      'database' => 'my-app-db',
      'host'     => 'a.host',
      'username' => 'user',
      'password' => 'pass',
    }

    ActiveRecord::Base.stubs(:connection).returns(@connection)
    ActiveRecord::Base.stubs(:establish_connection).returns(true)
  end

  def test_structure_dump
    filename = "awesome-file.sql"
    Kernel.expects(:system).with("defncopy -S a.host -D my-app-db -U user -P pass -o #{filename} a_table a_view").returns(true)
    File.expects(:read).with(filename).returns('')
    File.expects(:open).with(filename, "w")

    ActiveRecord::Tasks::DatabaseTasks.structure_dump(@configuration, filename)
  end
end

class SQLServerStructureLoadTest < ActiveRecord::TestCase
  def setup
    @connection    = stub
    @configuration = {
      'adapter'  => 'sqlserver',
      'database' => 'my-app-db',
      'host'     => 'a.host',
      'username' => 'user',
      'password' => 'pass',
    }

    ActiveRecord::Base.stubs(:connection).returns(@connection)
  end

  def test_structure_load
    filename = "awesome-file.sql"
    Kernel.expects(:system).with("tsql -S a.host -D my-app-db -U user -P pass < awesome-file.sql").returns(true)

    ActiveRecord::Tasks::DatabaseTasks.structure_load(@configuration, filename)
  end

  def test_structure_load_accepts_path_with_spaces
    filename = "awesome file.sql"
    Kernel.expects(:system).with("tsql -S a.host -D my-app-db -U user -P pass < awesome\\ file.sql").returns(true)

    ActiveRecord::Tasks::DatabaseTasks.structure_load(@configuration, filename)
  end
end

