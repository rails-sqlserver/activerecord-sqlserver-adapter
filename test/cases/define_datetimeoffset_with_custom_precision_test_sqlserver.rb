# frozen_string_literal: true

require "cases/helper_sqlserver"
require "migrations/create_table_with_customized_precision_datetimeoffset"

class DefineDatetimeoffsetWithCustomPrecisionTestSQLServer < ActiveRecord::TestCase
  before do
    @old_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    CreateTableWithCustomizedPrecisionDatetimeoffset.new.up
  end

  after do
    CreateTableWithCustomizedPrecisionDatetimeoffset.new.down
    ActiveRecord::Migration.verbose = @old_verbose
  end

  let(:column_with_custom_precision) do
    connection.columns("test_custom_precision_datetimeoffset").find do |column|
      column.name == "datetimeoffset_with_custom_precision"
    end
  end

  it "has the speficied precision" do
    _(column_with_custom_precision.precision).must_equal 5
  end
end
