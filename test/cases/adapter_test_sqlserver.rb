require 'cases/sqlserver_helper'
require 'models/task'
require 'models/topic'

class AdapterTestSqlserver < ActiveRecord::TestCase
  
  def setup
    @connection = ActiveRecord::Base.connection
  end
  
  
  def test_update_sql_statement_invalid
    assert_raise(ActiveRecord::StatementInvalid) { Topic.connection.update_sql("UPDATE XXX") }
  end
  
  def test_real_column_has_float_type
    assert_equal :float, TableWithRealColumn.columns_hash["real_number"].type
  end
  
  def test_date_insertion_when_language_is_german
    @connection.execute("SET LANGUAGE deutsch")
    assert_nothing_raised do
      Task.create(:starting => Time.utc(2000, 1, 31, 5, 42, 0), :ending => Date.new(2006, 12, 31))
    end
  ensure
    @connection.execute("SET LANGUAGE us_english") rescue nil
  end
  
  def test_indexes_with_descending_order
    @connection.execute "CREATE INDEX idx_credit_limit ON accounts (credit_limit DESC)" rescue nil
    assert_equal ["credit_limit"], @connection.indexes('accounts').first.columns
  ensure
    @connection.execute "DROP INDEX accounts.idx_credit_limit"
  end
  
  def test_escaped_table_name
    old_table_name, new_table_name = Topic.table_name, '[topics]'
    Topic.table_name = new_table_name
    assert_nothing_raised { ActiveRecord::Base.connection.select_all "SELECT * FROM #{new_table_name}" }
    assert_equal new_table_name, Topic.table_name
    assert_equal 12, Topic.columns.length
  ensure
    Topic.table_name = old_table_name
  end
  
  
end

