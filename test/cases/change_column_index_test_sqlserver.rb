# frozen_string_literal: true

require "cases/helper_sqlserver"

class ChangeColumnIndexTestSqlServer < ActiveRecord::TestCase
  class CreateClientsWithUniqueIndex < ActiveRecord::Migration[8.0]
    def up
      create_table :clients do |t|
        t.string :name, limit: 15
      end
      add_index :clients, :name, unique: true
    end

    def down
      drop_table :clients
    end
  end

  class ChangeClientsNameLength < ActiveRecord::Migration[8.0]
    def up
      change_column :clients, :name, :string, limit: 30
    end
  end

  before do
    CreateClientsWithUniqueIndex.new.up
  end

  after do
    CreateClientsWithUniqueIndex.new.down
  end

  def test_index_uniqueness_is_maintained_after_column_change
    indexes = ActiveRecord::Base.connection.indexes("clients")
    columns = ActiveRecord::Base.connection.columns("clients")
    assert_equal columns.find { |column| column.name == "name" }.limit, 15
    assert_equal indexes.size, 1
    assert_equal indexes.first.name, "index_clients_on_name"
    assert indexes.first.unique

    ChangeClientsNameLength.new.up

    indexes = ActiveRecord::Base.connection.indexes("clients")
    columns = ActiveRecord::Base.connection.columns("clients")
    assert_equal columns.find { |column| column.name == "name" }.limit, 30
    assert_equal indexes.size, 1
    assert_equal indexes.first.name, "index_clients_on_name"
    assert indexes.first.unique
  end
end
