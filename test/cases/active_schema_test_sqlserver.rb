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
      assert_sql('CREATE INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo])') do
        connection.add_index :schema_test_table, "foo"
      end
    end

    it 'unique index' do
      assert_sql('CREATE UNIQUE INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo])') do
        connection.add_index :schema_test_table, "foo", unique: true
      end
    end

    it 'where condition on index' do
      assert_sql("CREATE INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo]) WHERE state = 'active'") do
        connection.add_index :schema_test_table, "foo", where: "state = 'active'"
      end
    end

    it 'if index does not exist' do
      assert_sql("IF NOT EXISTS (SELECT name FROM sysindexes WHERE name = 'index_schema_test_table_on_foo') " \
                 "CREATE INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo])") do
        connection.add_index :schema_test_table, "foo", if_not_exists: true
      end
    end

    it 'clustered index' do
      assert_sql('CREATE CLUSTERED INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo])') do
        connection.add_index :schema_test_table, "foo", type: :clustered
      end
    end

    it 'nonclustered index' do
      assert_sql('CREATE NONCLUSTERED INDEX [index_schema_test_table_on_foo] ON [schema_test_table] ([foo])') do
        connection.add_index :schema_test_table, "foo", type: :nonclustered
      end
    end
  end

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
