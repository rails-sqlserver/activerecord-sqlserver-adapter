# frozen_string_literal: true

require "cases/helper_sqlserver"

class CreateTableWithColumnOptions < ActiveRecord::Migration[5.2]
  def up
    create_table :test_column_option_order do |t|
      t.text :not_null_text_with_collation, null: false, collation: "Latin1_General_CS_AS"
    end
  end

  def down
    drop_table :test_column_option_order
  end
end


class CreateTableOptionOrderTestSQLServer < ActiveRecord::TestCase
  before do
    @old_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
  end

  after do
    CreateTableWithColumnOptions.new.down
    ActiveRecord::Migration.verbose = @old_verbose
  end

  it "can create column with NOT NULL and COLLATE" do
    assert_nothing_raised { CreateTableWithColumnOptions.new.up }
  end
end

