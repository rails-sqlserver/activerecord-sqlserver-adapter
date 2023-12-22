# frozen_string_literal: true

class CreateTableWithCustomizedPrecisionDatetimeoffset < ActiveRecord::Migration[5.2]
  def up
    create_table :test_custom_precision_datetimeoffset do |t|
      t.datetimeoffset :datetimeoffset_with_custom_precision, precision: 5
    end
  end

  def down
    drop_table :test_custom_precision_datetimeoffset
  end
end
