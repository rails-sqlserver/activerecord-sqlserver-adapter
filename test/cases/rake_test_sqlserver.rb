require 'cases/helper_sqlserver'

class SQLServerRakeTest < ActiveRecord::TestCase

  self.use_transactional_fixtures = false

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
    db_tasks.create configuration
    connection.current_database.must_equal(new_database)
  end

  it 'creates database with default collation' do
    db_tasks.create configuration
    connection.collation.must_equal 'SQL_Latin1_General_CP1_CI_AS'
  end

  it 'creates database with given collation' do
    db_tasks.create configuration.merge('collation' => 'Latin1_General_CI_AS')
    connection.collation.must_equal 'Latin1_General_CI_AS'
  end

  it 'prints error message when database exists' do
    db_tasks.create configuration
    message = capture(:stderr) { db_tasks.create configuration }
    message.must_match %r{activerecord_unittest_tasks already exists}
  end

end

class SQLServerRakeDropTest < SQLServerRakeTest

  self.azure_skip = false

  it 'drops database and uses master' do
    db_tasks.create configuration
    db_tasks.drop configuration
    connection.current_database.must_equal 'master'
  end

  it 'prints error message when database does not exist' do
    message = capture(:stderr) { db_tasks.drop configuration.merge('database' => 'doesnotexist') }
    message.must_match %r{'doesnotexist' does not exist}
  end

end

class SQLServerRakePurgeTest < SQLServerRakeTest

  before do
    db_tasks.create(configuration)
    connection.create_table :users, force: true do |t|
      t.string :name, :email
      t.timestamps null: false
    end
  end

  it 'clears active connections, drops database, and recreates with established connection' do
    connection.current_database.must_equal(new_database)
    connection.tables.must_include 'users'
    db_tasks.purge(configuration)
    connection.current_database.must_equal(new_database)
    connection.tables.wont_include 'users'
  end

end

class SQLServerRakeCharsetTest < SQLServerRakeTest

  before { db_tasks.create(configuration) }

  it 'retrieves charset' do
    db_tasks.charset(configuration).must_equal 'iso_1'
  end

end

class SQLServerRakeCollationTest < SQLServerRakeTest

  before { db_tasks.create(configuration) }

  it 'retrieves collation' do
    db_tasks.collation(configuration).must_equal 'SQL_Latin1_General_CP1_CI_AS'
  end

end

class SQLServerRakeStructureDumpLoadTest < SQLServerRakeTest

  let(:filename) { File.join ARTest::SQLServer.migrations_root, 'structure.sql' }
  let(:filedata) { File.read(filename) }

  before do
    db_tasks.create(configuration)
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
    filedata.wont_match %r{\AUSE.*\z}
    filedata.wont_match %r{\AGO.*\z}
    filedata.must_match %r{email\s+nvarchar\(4000\)}
    filedata.must_match %r{background1\s+nvarchar\(max\)}
    filedata.must_match %r{background2\s+text\s+}
  end

  it 'can load dumped structure' do
    skip 'debug defncopy on windows later' if host_windows?
    quietly { db_tasks.structure_dump configuration, filename }
    filedata.must_match %r{CREATE TABLE dbo\.users}
    db_tasks.purge(configuration)
    connection.tables.wont_include 'users'
    db_tasks.load_schema_for configuration, :sql, filename
    connection.tables.must_include 'users'
  end

end
