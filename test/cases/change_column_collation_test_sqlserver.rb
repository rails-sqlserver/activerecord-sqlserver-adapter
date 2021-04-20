# frozen_string_literal: true

require "cases/helper_sqlserver"
require "migrations/create_clients_and_change_column_collation"

class ChangeColumnCollationTestSqlServer < ActiveRecord::TestCase
  before do
    @old_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    CreateClientsAndChangeColumnCollation.new.up
  end

  after do
    CreateClientsAndChangeColumnCollation.new.down
    ActiveRecord::Migration.verbose = @old_verbose
  end

  def find_column(table, name)
    table.find { |column| column.name == name }
  end

  let(:clients_table) { connection.columns("clients") }
  let(:name_column) { find_column(clients_table, "name") }
  let(:code_column) { find_column(clients_table, "code") }

  it "change column collation to other than default" do
    _(name_column.collation).must_equal "SQL_Latin1_General_CP1_CS_AS"
  end

  it "change column collation to default" do
    _(code_column.collation).must_equal "SQL_Latin1_General_CP1_CI_AS"
  end
end
