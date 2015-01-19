require 'cases/helper_sqlserver'

class DatabaseStatementsTestSQLServer < ActiveRecord::TestCase

  self.use_transactional_fixtures = false

  after { connection.use_database }

  it 'create database' do
    connection.create_database 'activerecord_unittest3'
    database_name = connection.select_value "SELECT name FROM master.dbo.sysdatabases WHERE name = 'activerecord_unittest3'"
    assert_equal 'activerecord_unittest3', database_name
  end

  it 'drop database' do
    connection.drop_database 'activerecord_unittest3'
    database_name = connection.select_value "SELECT name FROM master.dbo.sysdatabases WHERE name = 'activerecord_unittest3'"
    assert_equal nil, database_name
  end

  it 'create/use/drop database with name with dots' do
    connection.drop_database '[activerecord.unittest]' rescue nil
    connection.create_database '[activerecord.unittest]'
    database_name = connection.select_value "SELECT name FROM master.dbo.sysdatabases WHERE name = 'activerecord.unittest'"
    assert_equal 'activerecord.unittest', database_name
    connection.use_database '[activerecord.unittest]'
    connection.use_database
    connection.drop_database '[activerecord.unittest]'
  end

  describe 'with collation' do

    after { connection.drop_database 'activerecord_unittest3' }

    it 'create database with default collation for the server' do
      connection.create_database 'activerecord_unittest3'
      default_collation = connection.select_value "SELECT SERVERPROPERTY('Collation')"
      database_collation = connection.select_value "SELECT DATABASEPROPERTYEX('activerecord_unittest3', 'Collation') SQLCollation"
      assert_equal default_collation, database_collation
    end

    it 'create database with collation set by the method' do
      connection.create_database 'activerecord_unittest3', collation: 'SQL_Latin1_General_CP1_CI_AS'
      collation = connection.select_value "SELECT DATABASEPROPERTYEX('activerecord_unittest3', 'Collation') SQLCollation"
      assert_equal 'SQL_Latin1_General_CP1_CI_AS', collation
    end

    it 'create database with collation set by the config' do
      connection.instance_variable_get(:@connection_options)[:collation] = 'SQL_Latin1_General_CP1_CI_AS'
      connection.create_database 'activerecord_unittest3'
      collation = connection.select_value "SELECT DATABASEPROPERTYEX('activerecord_unittest3', 'Collation') SQLCollation"
      assert_equal 'SQL_Latin1_General_CP1_CI_AS', collation
    end

  end

end
