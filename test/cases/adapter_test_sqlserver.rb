require 'cases/sqlserver_helper'
require 'models/task'
require 'models/topic'

class AdapterTestSqlserver < ActiveRecord::TestCase
  
  def setup
    @connection = ActiveRecord::Base.connection
  end
  
  
  should 'raise invalid statement error' do
    assert_raise(ActiveRecord::StatementInvalid) { Topic.connection.update_sql("UPDATE XXX") }
  end
  
  should 'return real_number as float' do
    assert_equal :float, TableWithRealColumn.columns_hash["real_number"].type
  end
  
  context 'With different language' do

    teardown do
      @connection.execute("SET LANGUAGE us_english") rescue nil
    end

    should 'do a date insertion when language is german' do
      @connection.execute("SET LANGUAGE deutsch")
      assert_nothing_raised do
        Task.create(:starting => Time.utc(2000, 1, 31, 5, 42, 0), :ending => Date.new(2006, 12, 31))
      end
    end

  end
  
  context 'For indexes' do
    
    setup do
      @connection.execute "CREATE INDEX idx_credit_limit ON accounts (credit_limit DESC)" rescue nil
    end
    
    teardown do
      @connection.execute "DROP INDEX accounts.idx_credit_limit"
    end

    should 'have indexes with descending order' do
      assert_equal ["credit_limit"], @connection.indexes('accounts').first.columns
    end

  end
  
  context 'For .table_name' do

    setup do
      @old_table_name, @new_table_name = Topic.table_name, '[topics]'
      Topic.table_name = @new_table_name
    end
    
    teardown do
      Topic.table_name = @old_table_name
    end
    
    should 'escape table name' do
      assert_nothing_raised { @connection.select_all "SELECT * FROM #{@new_table_name}" }
      assert_equal @new_table_name, Topic.table_name
      assert_equal 12, Topic.columns.length
    end

  end
  
  
end

