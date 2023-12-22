# frozen_string_literal: true

require "cases/helper_sqlserver"
require "migrations/create_table_with_precision_7_time"

class CreatePrecision7ColumnTestSQLServer < ActiveRecord::TestCase
  before do
    @old_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
  end

  after do
    CreateTableWithPrecision7Time.new.down
    ActiveRecord::Migration.verbose = @old_verbose
  end

  it "can add time column whose precision is 7" do
    assert_nothing_raised { CreateTableWithPrecision7Time.new.up }
  end
end
