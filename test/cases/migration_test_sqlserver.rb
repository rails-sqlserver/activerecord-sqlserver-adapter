require 'cases/sqlserver_helper'
require 'models/person'

class MigrationTestSqlserver < ActiveRecord::TestCase
  
  def setup
    @connection = ActiveRecord::Base.connection
  end
  
  context 'For transactions' do
    
    setup do
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
      begin
        ActiveRecord::Migrator.up(SQLSERVER_MIGRATIONS_ROOT+'/transaction_table')
      rescue Exception => e
        assert_match %r|this and all later migrations canceled|, e.message
      end
      assert_does_not_contain @trans_test_table1, @connection.tables
      assert_does_not_contain @trans_test_table2, @connection.tables
    end
    
  end
  
  context 'For changing column' do
    
    should 'not raise exception when column contains default constraint' do
      lock_version_column = Person.columns_hash['lock_version']
      assert_equal :integer, lock_version_column.type
      assert lock_version_column.default.present?
      assert_nothing_raised { @connection.change_column 'people', 'lock_version', :string }
      Person.reset_column_information
      lock_version_column = Person.columns_hash['lock_version']
      assert_equal :string, lock_version_column.type
      assert lock_version_column.default.nil?
    end
    
    should 'not drop the default contraint if just renaming' do
      find_default = lambda do 
        @connection.select_all("EXEC sp_helpconstraint 'defaults','nomsg'").select do |row|     
          row['constraint_type'] == "DEFAULT on column decimal_number"
        end.last
      end
      default_before = find_default.call
      @connection.change_column :defaults, :decimal_number, :decimal, :precision => 4
      default_after = find_default.call
      assert default_after
      assert_equal default_before['constraint_keys'], default_after['constraint_keys']
    end
    
  end
  
end

if ActiveRecord::TestCase.sqlserver_azure?
  class MigrationTest < ActiveRecord::TestCase
    COERCED_TESTS = [:test_migrator_db_has_no_schema_migrations_table]
    include SqlserverCoercedTest
    def test_coerced_test_migrator_db_has_no_schema_migrations_table ; assert true ; end  
  end
end

