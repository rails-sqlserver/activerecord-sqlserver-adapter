# frozen_string_literal: true

class CreateClientsAndChangeColumnNull < ActiveRecord::Migration[5.2]
  def up
    create_table :clients do |t|
      t.string :name
      t.string :code
      t.decimal :value

      t.timestamps
    end

    change_column :clients, :name, :string, limit: 15
    change_column :clients, :code, :string, default: "n/a"
    change_column :clients, :value, :decimal, precision: 32, scale: 8

    change_column_null :clients, :name, false
    change_column_null :clients, :code, false
    change_column_null :clients, :value, false
  end

  def down
    drop_table :clients
  end
end
