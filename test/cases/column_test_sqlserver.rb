require 'cases/sqlserver_helper'
require 'models/binary'

class ColumnTestSqlserver < ActiveRecord::TestCase
  
  def setup
    @column_klass = ActiveRecord::ConnectionAdapters::SQLServerColumn
  end
  
  
  context 'For :binary columns' do

    setup do
      @binary_string = "GIF89a\001\000\001\000\200\000\000\377\377\377\000\000\000!\371\004\000\000\000\000\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;"
      @saved_bdata = Binary.create!(:data => @binary_string)
    end
    
    should 'read and write binary data equally' do
      assert_equal @binary_string, Binary.find(@saved_bdata).data
    end
    
    should 'quote data for sqlserver with literal 0x prefix' do
      # See the output of the stored procedure: 'exec sp_datatype_info'
      sqlserver_encoded_bdata = "0x47494638396101000100800000ffffff00000021f90400000000002c00000000010001000002024401003b"
      assert_equal sqlserver_encoded_bdata, @column_klass.string_to_binary(@binary_string) 
    end

  end
  
  
  
end
