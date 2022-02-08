# frozen_string_literal: true

require "cases/helper_sqlserver"

class ActiveSchemaTestSQLServer < ActiveRecord::TestCase
  describe "index types" do
    before do
      connection.create_table :index_types, force: true, id: false do |t|
        t.column :foo, :string, limit: 100
      end
    end

    after do
      connection.drop_table :index_types rescue nil
    end

    it 'default index' do
      assert_sql('CREATE INDEX [index_index_types_on_foo] ON [index_types] ([foo])') do
        connection.add_index :index_types, "foo"
      end
    end

    it 'clustered index' do
      assert_sql('CREATE clustered INDEX [index_index_types_on_foo] ON [index_types] ([foo])') do
        connection.add_index :index_types, "foo", type: :clustered
      end
    end

    it 'nonclustered index' do
      assert_sql('CREATE nonclustered INDEX [index_index_types_on_foo] ON [index_types] ([foo])') do
        connection.add_index :index_types, "foo", type: :nonclustered
      end
    end
  end
end
