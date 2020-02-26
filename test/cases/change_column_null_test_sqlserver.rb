require 'cases/helper_sqlserver'
require 'migrations/create_clients_and_change_column_null'

class ChangeColumnNullTestSqlServer < ActiveRecord::TestCase
  before do
    @old_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    CreateClientsAndChangeColumnNull.new.up
  end

  after do
    CreateClientsAndChangeColumnNull.new.down
    ActiveRecord::Migration.verbose = @old_verbose
  end

  def find_column(table, name)
    table.find { |column| column.name == name }
  end

  let(:clients_table) { connection.columns('clients') }
  let(:name_column) { find_column(clients_table, 'name') }
  let(:code_column) { find_column(clients_table, 'code') }
  let(:value_column) { find_column(clients_table, 'value') }

  describe '#change_column_null' do
    it 'does not change the column limit' do
      _(name_column.limit).must_equal 15
    end

    it 'does not change the column default' do
      _(code_column.default).must_equal 'n/a'
    end

    it 'does not change the column precision' do
      _(value_column.precision).must_equal 32
    end

    it 'does not change the column scale' do
      _(value_column.scale).must_equal 8
    end
  end
end
