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


end

