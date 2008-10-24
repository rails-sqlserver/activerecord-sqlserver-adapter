require 'cases/sqlserver_helper'

class MigrationTestSqlserver < ActiveRecord::TestCase
  
  context 'For transactions' do
    
    setup do
      @connection = ActiveRecord::Base.connection
      @trans_test_table1 = 'sqlserver_trans_table1'
      @trans_test_table2 = 'sqlserver_trans_table2'
      @trans_tables = [@trans_test_table1,@trans_test_table2]
    end
    
    teardown do
      @trans_tables.each do |table_name|
        ActiveRecord::Migration.drop_table(table_name) if @connection.tables.include?(table_name)
      end
    end
    
    should 'not create a tables if error in migrations' do
      ActiveRecord::Migrator.up(SQLSERVER_MIGRATIONS_ROOT+'/transaction_table')
      assert_does_not_contain @trans_test_table1, @connection.tables
      assert_does_not_contain @trans_test_table2, @connection.tables
    end
    
  end
  
  
end

