require 'cases/helper_sqlserver'

class SQLServerRakeTest < ActiveRecord::TestCase

  self.use_transactional_tests = false

  cattr_accessor :azure_skip
  self.azure_skip = connection_sqlserver_azure?

  let(:db_tasks)              { ActiveRecord::Tasks::DatabaseTasks }
  let(:new_database)          { 'activerecord_unittest_tasks' }
  let(:default_configuration) { ARTest.connection_config['arunit'] }
  let(:configuration)         { default_configuration.merge('database' => new_database) }

  before { skip 'on azure' if azure_skip }
  before { disconnect! unless azure_skip }
  after  { reconnect unless azure_skip }

  private

  def disconnect!
    connection.disconnect!
  end

  def reconnect
    config = default_configuration
    if connection_sqlserver_azure?
      ActiveRecord::Base.establish_connection(config.merge('database' => 'master'))
      connection.drop_database(new_database) rescue nil
      disconnect!
      ActiveRecord::Base.establish_connection(config)
    else
      ActiveRecord::Base.establish_connection(config)
      connection.drop_database(new_database) rescue nil
    end
  end

end

class SQLServerRakeCreateTest < SQLServerRakeTest

  self.azure_skip = false

  it 'establishes connection to database after create ' do
    quietly { db_tasks.create configuration }
    _(connection.current_database).must_equal(new_database)
  end

  it 'creates database with default collation' do
    quietly { db_tasks.create configuration }
    _(connection.collation).must_equal 'SQL_Latin1_General_CP1_CI_AS'
  end

  it 'creates database with given collation' do
    quietly { db_tasks.create configuration.merge('collation' => 'Latin1_General_CI_AS') }
    _(connection.collation).must_equal 'Latin1_General_CI_AS'
  end

  it 'prints error message when database exists' do
    quietly { db_tasks.create configuration }
    message = capture(:stderr) { db_tasks.create configuration }
    _(message).must_match %r{activerecord_unittest_tasks.*already exists}
  end

end

class SQLServerRakeDropTest < SQLServerRakeTest

  self.azure_skip = false

  it 'drops database and uses master' do
    quietly do
      db_tasks.create configuration
      db_tasks.drop configuration
    end
    _(connection.current_database).must_equal 'master'
  end

  it 'prints error message when database does not exist' do
    message = capture(:stderr) { db_tasks.drop configuration.merge('database' => 'doesnotexist') }
    _(message).must_match %r{'doesnotexist' does not exist}
  end

end

class SQLServerRakePurgeTest < SQLServerRakeTest

  before do
    quietly { db_tasks.create(configuration) }
    connection.create_table :users, force: true do |t|
      t.string :name, :email
      t.timestamps null: false
    end
  end

  it 'clears active connections, drops database, and recreates with established connection' do
    _(connection.current_database).must_equal(new_database)
    _(connection.tables).must_include 'users'
    quietly { db_tasks.purge(configuration) }
    _(connection.current_database).must_equal(new_database)
    _(connection.tables).wont_include 'users'
  end

end

class SQLServerRakeCharsetTest < SQLServerRakeTest

  before do
    quietly { db_tasks.create(configuration) }
  end

  it 'retrieves charset' do
    _(db_tasks.charset(configuration)).must_equal 'iso_1'
  end

end

class SQLServerRakeCollationTest < SQLServerRakeTest

  before do
    quietly { db_tasks.create(configuration) }
  end

  it 'retrieves collation' do
    _(db_tasks.collation(configuration)).must_equal 'SQL_Latin1_General_CP1_CI_AS'
  end

end

class SQLServerRakeStructureDumpLoadTest < SQLServerRakeTest

  let(:filename) { File.join ARTest::SQLServer.migrations_root, 'structure.sql' }
  let(:filedata) { File.read(filename) }

  before do
    quietly { db_tasks.create(configuration) }
    connection.create_table :users, force: true do |t|
      t.string :name, :email
      t.text :background1
      t.text_basic :background2
      t.timestamps null: false
    end
  end

  after do
    FileUtils.rm_rf(filename)
  end

  it 'dumps structure and accounts for defncopy oddities' do
    skip 'debug defncopy on windows later' if host_windows?
    quietly { db_tasks.structure_dump configuration, filename }
    _(filedata).wont_match %r{\AUSE.*\z}
    _(filedata).wont_match %r{\AGO.*\z}
    _(filedata).must_match %r{email\s+nvarchar\(4000\)}
    _(filedata).must_match %r{background1\s+nvarchar\(max\)}
    _(filedata).must_match %r{background2\s+text\s+}
  end

  it 'can load dumped structure' do
    skip 'debug defncopy on windows later' if host_windows?
    quietly { db_tasks.structure_dump configuration, filename }
    _(filedata).must_match %r{CREATE TABLE dbo\.users}
    db_tasks.purge(configuration)
    _(connection.tables).wont_include 'users'
    db_tasks.load_schema configuration, :sql, filename
    _(connection.tables).must_include 'users'
  end

end
