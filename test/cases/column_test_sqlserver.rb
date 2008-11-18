require 'cases/sqlserver_helper'
require 'models/binary'

class ColumnTestSqlserver < ActiveRecord::TestCase
  
  def setup
    @column_klass = ActiveRecord::ConnectionAdapters::SQLServerColumn
  end
  
  should 'return real_number as float' do
    assert_equal :float, TableWithRealColumn.columns_hash["real_number"].type
  end
  
  should 'know its #table_name and #table_klass' do
    Topic.columns.each do |column|
      assert_equal 'topics', column.table_name, "This column #{column.inspect} did not know it's #table_name"
      assert_equal Topic, column.table_klass, "This column #{column.inspect} did not know it's #table_klass"
    end
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
  
  context 'For .columns method' do

    should 'return correct scales and precisions for NumericData' do
      bank_balance = NumericData.columns_hash['bank_balance']
      big_bank_balance = NumericData.columns_hash['big_bank_balance']
      world_population = NumericData.columns_hash['world_population']
      my_house_population = NumericData.columns_hash['my_house_population']
      assert_equal [2,10], [bank_balance.scale, bank_balance.precision]
      assert_equal [2,15], [big_bank_balance.scale, big_bank_balance.precision]
      assert_equal [0,10], [world_population.scale, world_population.precision]
      assert_equal [0,2], [my_house_population.scale, my_house_population.precision]
    end
    
    should 'return correct null, limit, and default for Topic' do
      tch = Topic.columns_hash
      assert_equal false, tch['id'].null
      assert_equal true,  tch['title'].null
      assert_equal 255,   tch['author_name'].limit
      assert_equal true,  tch['approved'].default
      assert_equal 0,     tch['replies_count'].default
    end

  end
  
  
  
end
