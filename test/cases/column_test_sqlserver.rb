require 'cases/sqlserver_helper'

class ColumnTestSqlserver < ActiveRecord::TestCase
  
  def setup
    @column_klass = ActiveRecord::ConnectionAdapters::SQLServerColumn
  end
  
  def test_placeholder
    assert true 
  end
  
  
end
