require 'cases/sqlserver_helper'
require 'models_sqlserver/sql_server_natural_pk_data'
require 'models_sqlserver/sql_server_natural_pk_data_schema'

class SchemaTestSqlserver < ActiveRecord::TestCase

  setup do
    @connection = ActiveRecord::Base.connection
  end

  def read_schema_name(table_name)
    ActiveRecord::ConnectionAdapters::Sqlserver::Utils.unqualify_table_schema(table_name)
  end

  context 'When table is dbo schema' do

    should 'find primary key for tables with odd schema' do
      assert_equal 'legacy_id', @connection.primary_key('natural_pk_data')
      assert SqlServerNaturalPkData.columns_hash['legacy_id'].primary
    end

  end

  context 'When table is in non-dbo schema' do

    should 'work with #table_exists?' do
      assert @connection.table_exists?('test.sql_server_schema_natural_id')
    end

    should 'find primary key for tables with odd schema' do
      assert_equal 'legacy_id', @connection.primary_key('test.sql_server_schema_natural_id')
      assert SqlServerNaturalPkDataSchema.columns_hash['legacy_id'].primary
    end

    should "have only one identity column" do
      columns = @connection.columns("test.sql_server_schema_identity")
      assert_equal 2, columns.size
      assert_equal 1, columns.select{ |c| c.primary }.size
    end

    should "read only column properties for table in specific schema" do
      test_columns = @connection.columns("test.sql_server_schema_columns")
      dbo_columns = @connection.columns("dbo.sql_server_schema_columns")
      columns = @connection.columns("sql_server_schema_columns") # This returns table from dbo schema
      assert_equal 7, test_columns.size
      assert_equal 2, dbo_columns.size
      assert_equal 2, columns.size
      assert_equal 1, test_columns.select{ |c| c.primary }.size
      assert_equal 1, dbo_columns.select{ |c| c.primary }.size
      assert_equal 1, columns.select{ |c| c.primary }.size
    end

    should "return schema name in all cases" do
      assert_nil read_schema_name("table")
      assert_equal "schema1", read_schema_name("schema1.table")
      assert_equal "schema2", read_schema_name("database.schema2.table")
      assert_equal "schema3", read_schema_name("server.database.schema3.table")
      assert_equal "schema3", read_schema_name("[server].[database].[schema3].[table]")
    end

    should "return correct varchar and nvarchar column limit (length) when table is in non dbo schema" do
      columns = @connection.columns("test.sql_server_schema_columns")
      assert_equal 255, columns.find {|c| c.name == 'name'}.limit
      assert_equal 1000, columns.find {|c| c.name == 'description'}.limit
      assert_equal 255, columns.find {|c| c.name == 'n_name'}.limit
      assert_equal 1000, columns.find {|c| c.name == 'n_description'}.limit
    end

  end


end

