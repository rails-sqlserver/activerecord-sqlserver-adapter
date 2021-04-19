# frozen_string_literal: true

class CreateClientsAndChangeColumnCollation < ActiveRecord::Migration[5.2]
  def up
    create_table :clients do |t|
      t.string :name
      t.string :code, collation: :SQL_Latin1_General_CP1_CS_AS

      t.timestamps
    end

    change_column :clients, :name, :string, collation: 'SQL_Latin1_General_CP1_CS_AS'
    change_column :clients, :code, :string, collation: 'SQL_Latin1_General_CP1_CI_AS'
  end

  def down
    drop_table :clients
  end
end
