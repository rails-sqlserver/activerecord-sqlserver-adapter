require 'cases/helper_sqlserver'

class SchemaTestSQLServer < ActiveRecord::TestCase

  describe 'When table is dbo schema' do

    it 'find primary key for tables with odd schema' do
      _(connection.primary_key('sst_natural_pk_data')).must_equal 'legacy_id'
    end

  end

  describe 'When table is in non-dbo schema' do

    it 'work with table exists' do
      assert connection.data_source_exists?('test.sst_schema_natural_id')
      assert connection.data_source_exists?('[test].[sst_schema_natural_id]')
    end

    it 'find primary key for tables with odd schema' do
      _(connection.primary_key('test.sst_schema_natural_id')).must_equal 'legacy_id'
    end

    it "have only one identity column" do
      columns = connection.columns("test.sst_schema_identity")
      assert_equal 2, columns.size
      assert_equal 1, columns.select{ |c| c.is_identity? }.size
    end

    it "read only column properties for table in specific schema" do
      test_columns = connection.columns("test.sst_schema_columns")
      dbo_columns = connection.columns("dbo.sst_schema_columns")
      columns = connection.columns("sst_schema_columns") # This returns table from dbo schema
      assert_equal 7, test_columns.size
      assert_equal 2, dbo_columns.size
      assert_equal 2, columns.size
      assert_equal 1, test_columns.select{ |c| c.is_identity? }.size
      assert_equal 1, dbo_columns.select{ |c| c.is_identity? }.size
      assert_equal 1, columns.select{ |c| c.is_identity? }.size
    end

    it "return correct varchar and nvarchar column limit length when table is in non dbo schema" do
      columns = connection.columns("test.sst_schema_columns")
      assert_equal 255, columns.find {|c| c.name == 'name'}.limit
      assert_equal 1000, columns.find {|c| c.name == 'description'}.limit
      assert_equal 255, columns.find {|c| c.name == 'n_name'}.limit
      assert_equal 1000, columns.find {|c| c.name == 'n_description'}.limit
    end

  end

  describe 'When login has non-dbo schema' do

    before(:all) do
      # Create login and user
      sql= <<-SQL
        IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name = 'activerecordtestuser')
        BEGIN
          CREATE LOGIN [activerecordtestuser] WITH PASSWORD = '', CHECK_POLICY = OFF, DEFAULT_DATABASE = [activerecord_unittest]
        END
        USE [activerecord_unittest]
        DROP USER IF EXISTS [activerecordtestuser]
        CREATE USER [activerecordtestuser] FOR LOGIN [activerecordtestuser] WITH DEFAULT_SCHEMA = test
        GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: test TO [activerecordtestuser]
        GRANT VIEW DEFINITION TO [activerecordtestuser]
        COMMIT TRANSACTION
      SQL
      connection.execute sql # rescue nil

      # create view
      sql= <<-SQL
        IF OBJECT_ID('test.accounts', 'V') IS NOT NULL
          DROP VIEW test.accounts
        EXEC('CREATE VIEW test.accounts AS SELECT id AS account_id, firm_name AS account_name  FROM dbo.accounts')
      SQL
      connection.execute sql # rescue nil

      config = ARTest.connection_config['arunit']
      @conn2 = ActiveRecord::Base.establish_connection(config.merge('username' => 'activerecordtestuser')).connection
    end

    after(:all) do
      ActiveRecord::Base.remove_connection(@conn2)
      config = ARTest.connection_config['arunit']
      ActiveRecord::Base.establish_connection(config)
      sql=  <<-SQL
          DROP VIEW test.accounts
          DROP USER IF EXISTS [activerecordtestuser]
          DROP LOGIN [activerecordtestuser]
          COMMIT TRANSACTION
      SQL
      connection.execute sql # rescue nil
    end

    it 'table in schema exists' do
      assert @conn2.data_source_exists?('sst_schema_columns'), "table 'sst_schema_columns' is visible"
    end

    it 'tables from dbo schema not visible' do
      assert !@conn2.table_exists?('accounts'), "table 'accounts' (in dbo) not visible"
      assert @conn2.view_exists?('accounts'), "view 'accounts' (in test) visible"
    end

    class Accounts  < ActiveRecord::Base
    end

    it "access view" do
      assert_equal 2, Accounts.columns.count
      assert_equal "account_id", Accounts.columns[0].name
    end

    it "create accounts record" do
      data = Accounts.create!
      assert_equal 1, data.account_id
    end

  end
end

