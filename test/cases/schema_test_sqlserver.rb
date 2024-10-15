# frozen_string_literal: true

require "cases/helper_sqlserver"

class SchemaTestSQLServer < ActiveRecord::TestCase
  describe "When table is dbo schema" do
    it "find primary key for tables with odd schema" do
      _(connection.primary_key("sst_natural_pk_data")).must_equal "legacy_id"
    end
  end

  describe "When table is in non-dbo schema" do
    it "work with table exists" do
      assert connection.data_source_exists?("test.sst_schema_natural_id")
      assert connection.data_source_exists?("[test].[sst_schema_natural_id]")
    end

    it "find primary key for tables with odd schema" do
      _(connection.primary_key("test.sst_schema_natural_id")).must_equal "legacy_id"
    end

    it "have only one identity column" do
      columns = connection.columns("test.sst_schema_identity")

      assert_equal 2, columns.size
      assert_equal 1, columns.select { |c| c.is_identity? }.size
    end

    it "read only column properties for table in specific schema" do
      test_columns = connection.columns("test.sst_schema_columns")
      dbo_columns = connection.columns("dbo.sst_schema_columns")
      columns = connection.columns("sst_schema_columns") # This returns table from dbo schema

      assert_equal 7, test_columns.size
      assert_equal 2, dbo_columns.size
      assert_equal 2, columns.size
      assert_equal 1, test_columns.select { |c| c.is_identity? }.size
      assert_equal 1, dbo_columns.select { |c| c.is_identity? }.size
      assert_equal 1, columns.select { |c| c.is_identity? }.size
    end

    it "return correct varchar and nvarchar column limit length when table is in non-dbo schema" do
      columns = connection.columns("test.sst_schema_columns")

      assert_equal 255, columns.find { |c| c.name == "name" }.limit
      assert_equal 1000, columns.find { |c| c.name == "description" }.limit
      assert_equal 255, columns.find { |c| c.name == "n_name" }.limit
      assert_equal 1000, columns.find { |c| c.name == "n_description" }.limit
    end
  end

  describe "parsing table name from raw SQL" do
    describe 'SELECT statements' do
      it do
        assert_equal "[sst_schema_columns]", connection.send(:get_raw_table_name, "SELECT [sst_schema_columns].[id] FROM [sst_schema_columns]")
      end

      it do
        assert_equal "sst_schema_columns", connection.send(:get_raw_table_name, "SELECT [sst_schema_columns].[id] FROM sst_schema_columns")
      end

      it do
        assert_equal "[WITH - SPACES]", connection.send(:get_raw_table_name, "SELECT id FROM [WITH - SPACES]")
      end

      it do
        assert_equal "[WITH - SPACES$DOLLAR]", connection.send(:get_raw_table_name, "SELECT id FROM [WITH - SPACES$DOLLAR]")
      end

      it do
        assert_nil connection.send(:get_raw_table_name, nil)
      end
    end

    describe 'INSERT statements' do
      it do
        assert_equal "[dashboards]", connection.send(:get_raw_table_name, "INSERT INTO [dashboards] DEFAULT VALUES; SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident")
      end

      it do
        assert_equal "lock_without_defaults", connection.send(:get_raw_table_name, "INSERT INTO lock_without_defaults(title) VALUES('title1')")
      end

      it do
        assert_equal "json_data_type", connection.send(:get_raw_table_name, "insert into json_data_type (payload) VALUES ('null')")
      end

      it do
        assert_equal "[auto_increments]", connection.send(:get_raw_table_name, "INSERT INTO [auto_increments] OUTPUT INSERTED.[id] DEFAULT VALUES")
      end

      it do
        assert_equal "[WITH - SPACES]", connection.send(:get_raw_table_name, "EXEC sp_executesql N'INSERT INTO [WITH - SPACES] ([external_id]) OUTPUT INSERTED.[id] VALUES (@0)', N'@0 bigint', @0 = 10")
      end

      it do
        assert_equal "[test].[aliens]", connection.send(:get_raw_table_name, "EXEC sp_executesql N'INSERT INTO [test].[aliens] ([name]) OUTPUT INSERTED.[id] VALUES (@0)', N'@0 varchar(255)', @0 = 'Trisolarans'")
      end

      it do
        assert_equal "[with].[select notation]", connection.send(:get_raw_table_name, "INSERT INTO [with].[select notation] SELECT * FROM [table_name]")
      end
    end
  end
end
