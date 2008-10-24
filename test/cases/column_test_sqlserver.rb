require 'cases/sqlserver_helper'

class ColumnTestSqlserver < ActiveRecord::TestCase
  
  def setup
    @column_klass = ActiveRecord::ConnectionAdapters::SQLServerColumn
  end
  
  should 'be a placeholder' do
    assert true 
  end
  
  
end
