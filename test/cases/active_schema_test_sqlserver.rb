# frozen_string_literal: true

require "cases/helper_sqlserver"

class ActiveSchemaTestSQLServer < ActiveRecord::TestCase
  describe "indexes" do
    before do
      connection.create_table :schema_test_table, force: true, id: false do |t|
        t.column :foo, :string, limit: 100
        t.column :state, :string
      end
    end

    after do
      connection.drop_table :schema_test_table rescue nil
    end

    it 'default index' do
      assert_queries_match('CREATE INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo])') do
        connection.add_index :schema_test_table, "foo"
      end
    end

    it 'unique index' do
      assert_queries_match('CREATE UNIQUE INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo])') do
        connection.add_index :schema_test_table, "foo", unique: true
      end
    end

    it 'where condition on index' do
      assert_queries_match("CREATE INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo]) WHERE state = 'active'") do
        connection.add_index :schema_test_table, "foo", where: "state = 'active'"
      end
    end

    it 'if index does not exist' do
      assert_queries_match("IF NOT EXISTS (SELECT name FROM sysindexes WHERE name = 'index_schema_test_table_on_foo') " \
                 "CREATE INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo])") do
        connection.add_index :schema_test_table, "foo", if_not_exists: true
      end
    end

    it 'clustered index' do
      assert_queries_match('CREATE CLUSTERED INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo])') do
        connection.add_index :schema_test_table, "foo", type: :clustered
      end
    end

    it 'nonclustered index' do
      assert_queries_match('CREATE NONCLUSTERED INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo])') do
        connection.add_index :schema_test_table, "foo", type: :nonclustered
      end
    end
  end

  describe 'collation' do
    it "create column with NOT NULL and COLLATE" do
      assert_nothing_raised do
        connection.create_table :not_null_with_collation_table, force: true, id: false do |t|
          t.text :not_null_text_with_collation, null: false, collation: "Latin1_General_CS_AS"
        end
      end
    ensure
      connection.drop_table :not_null_with_collation_table rescue nil
    end
  end

  describe 'datetimeoffset precision' do
    it 'valid precisions are correct' do
      assert_nothing_raised do
        connection.create_table :datetimeoffset_precisions do |t|
          t.datetimeoffset :precision_default
          t.datetimeoffset :precision_5, precision: 5
          t.datetimeoffset :precision_7, precision: 7
        end
      end

      columns = connection.columns("datetimeoffset_precisions")

      assert_equal columns.find { |column| column.name == "precision_default" }.precision, 7
      assert_equal columns.find { |column| column.name == "precision_5" }.precision, 5
      assert_equal columns.find { |column| column.name == "precision_7" }.precision, 7
    ensure
      connection.drop_table :datetimeoffset_precisions rescue nil
    end

    it 'invalid precision raises exception' do
      assert_raise(ActiveRecord::ActiveRecordError) do
        connection.create_table :datetimeoffset_precisions do |t|
          t.datetimeoffset :precision_8, precision: 8
        end
      end
    ensure
      connection.drop_table :datetimeoffset_precisions rescue nil
    end
  end

  describe 'time precision' do
    it 'valid precisions are correct' do
      assert_nothing_raised do
        connection.create_table :time_precisions do |t|
          t.time :precision_default
          t.time :precision_5, precision: 5
          t.time :precision_7, precision: 7
        end
      end

      columns = connection.columns("time_precisions")

      assert_equal columns.find { |column| column.name == "precision_default" }.precision, 7
      assert_equal columns.find { |column| column.name == "precision_5" }.precision, 5
      assert_equal columns.find { |column| column.name == "precision_7" }.precision, 7
    ensure
      connection.drop_table :time_precisions rescue nil
    end

    it 'invalid precision raises exception' do
      assert_raise(ActiveRecord::ActiveRecordError) do
        connection.create_table :time_precisions do |t|
          t.time :precision_8, precision: 8
        end
      end
    ensure
      connection.drop_table :time_precisions rescue nil
    end
  end
end
