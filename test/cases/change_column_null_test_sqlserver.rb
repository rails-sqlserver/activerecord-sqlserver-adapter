# frozen_string_literal: true

require "cases/helper_sqlserver"
require "migrations/create_clients_and_change_column_null"
require "cases/migration/helper"

class ChangeColumnNullTestSqlServer < ActiveRecord::TestCase
  include ::ActiveRecord::Migration::TestHelper

  def find_column(table, column_name)
    connection.columns(table).find { |column| column.name == column_name.to_s }
  end

  describe "using migration" do
    before do
      @old_verbose = ActiveRecord::Migration.verbose
      ActiveRecord::Migration.verbose = false
      CreateClientsAndChangeColumnNull.new.up
    end

    after do
      CreateClientsAndChangeColumnNull.new.down
      ActiveRecord::Migration.verbose = @old_verbose
    end

    let(:name_column) { find_column("clients", "name") }
    let(:code_column) { find_column("clients", "code") }
    let(:value_column) { find_column("clients", "value") }

    it "does not change the column limit" do
      _(name_column.limit).must_equal 15
    end

    it "does not change the column default" do
      _(code_column.default).must_equal "n/a"
    end

    it "does not change the column precision" do
      _(value_column.precision).must_equal 32
    end

    it "does not change the column scale" do
      _(value_column.scale).must_equal 8
    end
  end

  it "datetime2 column" do
    add_column :test_models, :expiry_date, :datetime, precision: 6, null: true

    _(find_column(:test_models, :expiry_date).sql_type).must_equal "datetime2(6)"
    _(find_column(:test_models, :expiry_date).null).must_equal true

    connection.change_column_null(:test_models, :expiry_date, false)

    _(find_column(:test_models, :expiry_date).sql_type).must_equal "datetime2(6)"
    _(find_column(:test_models, :expiry_date).null).must_equal false
  ensure
    remove_column("test_models", "expiry_date")
  end

  it "datetime column" do
    add_column :test_models, :expiry_date, :datetime, precision: nil, null: true

    _(find_column(:test_models, :expiry_date).sql_type).must_equal "datetime"
    _(find_column(:test_models, :expiry_date).null).must_equal true

    connection.change_column_null(:test_models, :expiry_date, false)

    _(find_column(:test_models, :expiry_date).sql_type).must_equal "datetime"
    _(find_column(:test_models, :expiry_date).null).must_equal false
  ensure
    remove_column("test_models", "expiry_date")
  end
end
