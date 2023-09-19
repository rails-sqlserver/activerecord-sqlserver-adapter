# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/person"

class MigrationTestSQLServer < ActiveRecord::TestCase
  describe "For transactions" do
    before do
      @trans_test_table1 = "sqlserver_trans_table1"
      @trans_test_table2 = "sqlserver_trans_table2"
      @trans_tables = [@trans_test_table1, @trans_test_table2]
    end

    after do
      @trans_tables.each do |table_name|
        ActiveRecord::Migration.drop_table(table_name) if connection.tables.include?(table_name)
      end
    end

    it "not create a tables if error in migrations" do
      begin
        migrations_dir = File.join ARTest::SQLServer.migrations_root, "transaction_table"
        quietly { ActiveRecord::MigrationContext.new(migrations_dir, ActiveRecord::SchemaMigration).up }
      rescue Exception => e
        assert_match %r|this and all later migrations canceled|, e.message
      end
      _(connection.tables).wont_include @trans_test_table1
      _(connection.tables).wont_include @trans_test_table2
    end
  end

  describe "For changing column" do
    it "not raise exception when column contains default constraint" do
      lock_version_column = Person.columns_hash["lock_version"]
      assert_equal :integer, lock_version_column.type
      assert lock_version_column.default.present?
      assert_nothing_raised { connection.change_column "people", "lock_version", :string }
      Person.reset_column_information
      lock_version_column = Person.columns_hash["lock_version"]
      assert_equal :string, lock_version_column.type
      assert lock_version_column.default.nil?
      assert_nothing_raised { connection.change_column "people", "lock_version", :integer }
      Person.reset_column_information
    end

    it "not drop the default constraint if just renaming" do
      find_default = lambda do
        connection.execute_procedure(:sp_helpconstraint, "sst_string_defaults", "nomsg").select do |row|
          row["constraint_type"] == "DEFAULT on column string_with_pretend_paren_three"
        end.last
      end
      default_before = find_default.call
      connection.change_column :sst_string_defaults, :string_with_pretend_paren_three, :string, limit: 255
      default_after = find_default.call
      assert default_after
      assert_equal default_before["constraint_keys"], default_after["constraint_keys"]
    end

    it "change limit" do
      assert_nothing_raised { connection.change_column :people, :lock_version, :integer, limit: 8 }
    end

    it "change null and default" do
      assert_nothing_raised { connection.change_column :people, :first_name, :text, null: true, default: nil }
    end

    it "change collation" do
      assert_nothing_raised { connection.change_column :sst_string_collation, :string_with_collation, :varchar, collation: :SQL_Latin1_General_CP437_BIN }

      SstStringCollation.reset_column_information
      assert_equal "SQL_Latin1_General_CP437_BIN", SstStringCollation.columns_hash['string_with_collation'].collation
    end
  end

  describe "#create_schema" do
    it "creates a new schema" do
      connection.create_schema("some schema")

      schemas = connection.exec_query("select name from sys.schemas").to_a

      assert_includes schemas, { "name" => "some schema" }
    end

    it "creates a new schema with an owner" do
      connection.create_schema("some schema", :guest)

      schemas = connection.exec_query("select name, principal_id from sys.schemas").to_a

      assert_includes schemas, { "name" => "some schema", "principal_id" => 2 }
    end
  end

  describe "#change_table_schema" do
    before { connection.create_schema("foo") }

    it "transfer the given table to the given schema" do
      connection.change_table_schema("foo", "orders")

      assert connection.data_source_exists?("foo.orders")
    end
  end

  describe "#drop_schema" do
    before { connection.create_schema("some schema") }

    it "drops a schema" do
      schemas = connection.exec_query("select name from sys.schemas").to_a

      assert_includes schemas, { "name" => "some schema" }

      connection.drop_schema("some schema")

      schemas = connection.exec_query("select name from sys.schemas").to_a

      refute_includes schemas, { "name" => "some schema" }
    end
  end

  describe 'creating stored procedure' do
    it 'stored procedure contains inserts are created successfully' do
      sql = <<-SQL
          CREATE OR ALTER PROCEDURE do_some_task
          AS
          IF NOT EXISTS(SELECT * FROM sys.objects WHERE type = 'U' AND name = 'SomeTableName')
          BEGIN
            CREATE TABLE SomeTableName (SomeNum int PRIMARY KEY CLUSTERED);
            INSERT INTO SomeTableName(SomeNum) VALUES(1);
          END
        SQL

      assert_nothing_raised { connection.execute(sql) }
    ensure
      connection.execute("DROP PROCEDURE IF EXISTS dbo.do_some_task;")
    end
  end
end
