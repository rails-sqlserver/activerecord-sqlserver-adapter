# frozen_string_literal: true

class CreateTableWithPrecision7Time < ActiveRecord::Migration[5.2]
  def up
    create_table :test_precision_7_time do |t|
      t.time :time_with_precision_7, precision: 7
    end
  end

  def down
    drop_table :test_precision_7_time
  end
end
