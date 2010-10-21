require 'cases/sqlserver_helper'

class ConnectionModeTestSqlserver < ActiveRecord::TestCase
  
  context 'With :dblib/TinyTds connection' do

    setup do
      
    end

    should 'description' do
      
    end

  end if connection_mode_dblib?
  
  
  context 'With :odbc/ODBC connection' do

    setup do
      
    end

    should 'description' do
      
    end

  end if connection_mode_odbc?
  
  
  context 'With :adonet/ADO.NET connection' do

    setup do
      
    end

    should 'description' do
      
    end

  end  if connection_mode_adonet?
  
  
  
end
