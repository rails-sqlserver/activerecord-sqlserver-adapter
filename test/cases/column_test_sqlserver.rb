require 'cases/sqlserver_helper'
require 'models/binary'

class ColumnTestSqlserver < ActiveRecord::TestCase
  
  def setup
    @connection = ActiveRecord::Base.connection
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
  
  should 'return correct null, limit, and default for Topic' do
    tch = Topic.columns_hash
    assert_equal false, tch['id'].null
    assert_equal true,  tch['title'].null
    assert_equal 255,   tch['author_name'].limit
    assert_equal true,  tch['approved'].default
    assert_equal 0,     tch['replies_count'].default
  end
  
  context 'For binary columns' do

    setup do
      @binary_string = "GIF89a\001\000\001\000\200\000\000\377\377\377\000\000\000!\371\004\000\000\000\000\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;"
      @saved_bdata = Binary.create!(:data => @binary_string)
    end
    
    should 'read and write binary data equally' do
      assert_equal @binary_string, Binary.find(@saved_bdata).data
    end
    
    should 'have correct attributes' do
      column = Binary.columns_hash['data']
      assert_equal :binary, column.type
      assert_equal @connection.native_binary_database_type, column.sql_type
      assert_equal nil, column.limit
    end
    
    should 'quote data for sqlserver with literal 0x prefix' do
      # See the output of the stored procedure: 'exec sp_datatype_info'
      sqlserver_encoded_bdata = "0x47494638396101000100800000ffffff00000021f90400000000002c00000000010001000002024401003b"
      assert_equal sqlserver_encoded_bdata, @column_klass.string_to_binary(@binary_string) 
    end

  end
  
  context 'For string columns' do

    setup do
      @char         = SqlServerString.columns_hash['char']
      @char10       = SqlServerString.columns_hash['char_10']
      @varcharmax   = SqlServerString.columns_hash['varchar_max']
      @varcharmax10 = SqlServerString.columns_hash['varchar_max_10']
    end

    should 'have correct simplified types' do
      assert_equal :string, @char.type
      assert_equal :string, @char10.type
      assert_equal :text, @varcharmax.type, @varcharmax.inspect
      assert_equal :text, @varcharmax10.type, @varcharmax10.inspect
    end
    
    should 'have correct #sql_type per schema definition' do
      assert_equal 'char(1)',     @char.sql_type,       'Specifing a char type with no limit is 1 by SQL Server standards.'
      assert_equal 'char(10)',    @char10.sql_type,      @char10.inspect
      assert_equal 'varchar(max)', @varcharmax.sql_type,   'A -1 limit should be converted to max (max) type.'
      assert_equal 'varchar(max)', @varcharmax10.sql_type, 'A -1 limit should be converted to max (max) type.'
    end
    
    should 'have correct #limit per schema definition' do
      assert_equal 1,   @char.limit
      assert_equal 10,  @char10.limit
      assert_equal nil, @varcharmax.limit,   'Limits on max types are moot and we should let rails know that.'
      assert_equal nil, @varcharmax10.limit, 'Limits on max types are moot and we should let rails know that.'
    end

  end
  
  context 'For all national/unicode columns' do
    
    setup do
      @nchar         = SqlServerUnicode.columns_hash['nchar']
      @nvarchar      = SqlServerUnicode.columns_hash['nvarchar']
      @ntext         = SqlServerUnicode.columns_hash['ntext']
      @ntext10       = SqlServerUnicode.columns_hash['ntext_10']
      @nchar10       = SqlServerUnicode.columns_hash['nchar_10']
      @nvarchar100   = SqlServerUnicode.columns_hash['nvarchar_100']
      @nvarcharmax   = SqlServerUnicode.columns_hash['nvarchar_max']
      @nvarcharmax10 = SqlServerUnicode.columns_hash['nvarchar_max_10']
    end
    
    should 'all respond true to #is_utf8?' do
      SqlServerUnicode.columns_hash.except('id').values.each do |column|
        assert column.is_utf8?, "This column #{column.inspect} should have been a unicode column."
      end
    end
    
    should 'have correct simplified types' do
      assert_equal :string, @nchar.type
      assert_equal :string, @nvarchar.type
      assert_equal :text,   @ntext.type
      assert_equal :text,   @ntext10.type
      assert_equal :string, @nchar10.type
      assert_equal :string, @nvarchar100.type
      assert_equal :text, @nvarcharmax.type, @nvarcharmax.inspect
      assert_equal :text, @nvarcharmax10.type, @nvarcharmax10.inspect
    end
    
    should 'have correct #sql_type per schema definition' do
      assert_equal 'nchar(1)',      @nchar.sql_type,       'Specifing a nchar type with no limit is 1 by SQL Server standards.'
      assert_equal 'nvarchar(255)', @nvarchar.sql_type,    'Default nvarchar limit is 255.'
      assert_equal 'ntext',         @ntext.sql_type,       'Nice and clean ntext, limit means nothing here.'
      assert_equal 'ntext',         @ntext10.sql_type,     'Even a next with a limit of 10 specified will mean nothing.'
      assert_equal 'nchar(10)',     @nchar10.sql_type,     'An nchar with a limit of 10 needs to have it show up here.'
      assert_equal 'nvarchar(100)', @nvarchar100.sql_type, 'An nvarchar with a specified limit of 100 needs to show it.'
      assert_equal 'nvarchar(max)', @nvarcharmax.sql_type,   'A -1 limit should be converted to max (max) type.'
      assert_equal 'nvarchar(max)', @nvarcharmax10.sql_type, 'A -1 limit should be converted to max (max) type.'
    end
    
    should 'have correct #limit per schema definition' do
      assert_equal 1,   @nchar.limit
      assert_equal 255, @nvarchar.limit
      assert_equal nil, @ntext.limit,       'An ntext column limit is moot, it is a fixed variable length'
      assert_equal 10,  @nchar10.limit
      assert_equal 100, @nvarchar100.limit
      assert_equal nil, @nvarcharmax.limit,   'Limits on max types are moot and we should let rails know that.'
      assert_equal nil, @nvarcharmax10.limit, 'Limits on max types are moot and we should let rails know that.'
    end
    
  end
  
  context 'For datetime columns' do

    setup do
      @date = SqlServerChronic.columns_hash['date']
      @time = SqlServerChronic.columns_hash['time']
      @datetime = SqlServerChronic.columns_hash['datetime']
      @smalldatetime = SqlServerChronic.columns_hash['smalldatetime']
      @timestamp = SqlServerChronic.columns_hash['timestamp']
      @ss_timestamp = SqlServerChronic.columns_hash['ss_timestamp']
    end

    should 'have correct simplified type for uncast datetime' do
      assert_equal :datetime, @datetime.type
    end
    
    should 'use correct #sql_type for different sql server versions' do
      assert_equal 'datetime', @datetime.sql_type
      if sqlserver_2005?
        assert_equal 'datetime', @date.sql_type
        assert_equal 'datetime', @time.sql_type
      else
        assert_equal 'date', @date.sql_type
        assert_equal 'time', @time.sql_type
      end
    end
    
    should 'all be have nil #limit' do
      assert_equal nil, @date.limit
      assert_equal nil, @time.limit
      assert_equal nil, @datetime.limit
    end
    
    context 'with timestamps' do

      should 'use datetime sql type when using :timestamp in schema statements' do
        assert_equal :datetime, @timestamp.type
        assert_equal 'datetime', @timestamp.sql_type
      end
      
      should 'be able to use real sql server timestamp if you really want to' do
        assert_equal :binary, @ss_timestamp.type
        assert_equal 'timestamp', @ss_timestamp.sql_type
      end unless sqlserver_azure?
      
      should 'return :timestamp as a binaryish string' do
        chronic = SqlServerChronic.create!.reload
        assert_match %r|\000|, chronic.ss_timestamp
      end unless sqlserver_azure?

    end
    
    context 'For smalldatetime types' do
      
      should 'have created that type using rails migrations' do
        assert_equal 'smalldatetime', @smalldatetime.sql_type
      end
      
      should 'be able to insert column without truncation warnings or the like' do
        SqlServerChronic.create! :smalldatetime => Time.now
      end
      
      should 'be able to update column without truncation warnings or the like' do
        ssc = SqlServerChronic.create! :smalldatetime => 2.days.ago
        ssc.update_attributes! :smalldatetime => Time.now
      end

    end
    
    context 'which have coerced types' do
      
      setup do
        christmas_08 = "2008-12-25".to_time
        christmas_08_afternoon = "2008-12-25 12:00".to_time
        @chronic_date = SqlServerChronic.create!(:date => christmas_08).reload
        @chronic_time = SqlServerChronic.create!(:time => christmas_08_afternoon).reload
      end
      
      should 'have an inheritable attribute ' do
        assert SqlServerChronic.coerced_sqlserver_date_columns.include?('date') unless sqlserver_2008?
      end
      
      should 'have column and objects cast to date' do
        assert_equal :date, @date.type, "This column: \n#{@date.inspect}"
        assert_instance_of Date, @chronic_date.date
      end
      
      should 'have column objects cast to time' do
        assert_equal :time, @time.type, "This column: \n#{@time.inspect}"
        assert_instance_of Time, @chronic_time.time
      end
      
    end

  end
  
  context 'For decimal and numeric columns' do
    
    setup do
      @bank_balance = NumericData.columns_hash['bank_balance']
      @big_bank_balance = NumericData.columns_hash['big_bank_balance']
      @world_population = NumericData.columns_hash['world_population']
      @my_house_population = NumericData.columns_hash['my_house_population']
    end
    
    should 'have correct simplified types' do
      assert_equal :decimal, @bank_balance.type
      assert_equal :decimal, @big_bank_balance.type
      assert_equal :integer, @world_population.type, 'Since #extract_scale == 0'
      assert_equal :integer, @my_house_population.type, 'Since #extract_scale == 0'
    end
    
    should 'have correct #sql_type' do
      assert_equal 'decimal(10,2)', @bank_balance.sql_type
      assert_equal 'decimal(15,2)', @big_bank_balance.sql_type
      assert_equal 'decimal(10,0)', @world_population.sql_type
      assert_equal 'decimal(2,0)',  @my_house_population.sql_type
    end
    
    should 'have correct #limit' do
      assert_equal nil, @bank_balance.limit
      assert_equal nil, @big_bank_balance.limit
      assert_equal nil, @world_population.limit
      assert_equal nil, @my_house_population.limit
    end
    
    should 'return correct precisions and scales' do
      assert_equal [10,2], [@bank_balance.precision, @bank_balance.scale]
      assert_equal [15,2], [@big_bank_balance.precision, @big_bank_balance.scale]
      assert_equal [10,0], [@world_population.precision, @world_population.scale]
      assert_equal [2,0],  [@my_house_population.precision, @my_house_population.scale]
    end
    
  end
  
  context 'For float columns' do
    # NOTE: float limits are adjusted to 24 or 53 by the database as per
    # http://msdn.microsoft.com/en-us/library/ms173773.aspx
    # NOTE: floats with a limit of <= 24 are reduced to reals by sqlserver on creation

    setup do
      @temperature = FloatData.columns_hash['temperature']
      @freezing = FloatData.columns_hash['temperature_8']
      @mild = FloatData.columns_hash['temperature_24']
      @beach = FloatData.columns_hash['temperature_32']
      @desert = FloatData.columns_hash['temperature_53']
    end

    should 'have correct simplified types' do
      assert_equal :float, @temperature.type
      assert_equal :float, @freezing.type
      assert_equal :float, @mild.type
      assert_equal :float, @beach.type
      assert_equal :float, @desert.type
    end

    should 'have correct #sql_type' do
      assert_equal 'real(24)', @temperature.sql_type
      assert_equal 'real(24)', @freezing.sql_type
      assert_equal 'real(24)', @mild.sql_type
      assert_equal 'float(53)', @beach.sql_type
      assert_equal 'float(53)',  @desert.sql_type
    end

    should 'have correct #limit' do
      assert_equal 24, @temperature.limit
      assert_equal 24, @freezing.limit
      assert_equal 24, @mild.limit
      assert_equal 53, @beach.limit
      assert_equal 53, @desert.limit
    end

    should 'return nil precisions and scales' do
      assert_equal [nil,nil], [@temperature.precision, @temperature.scale]
      assert_equal [nil,nil], [@freezing.precision, @freezing.scale]
      assert_equal [nil,nil], [@mild.precision, @mild.scale]
      assert_equal [nil,nil], [@beach.precision, @beach.scale]
      assert_equal [nil,nil], [@desert.precision, @desert.scale]
    end

  end
  
  context 'For tinyint columns' do

    setup do
      @tinyint = SqlServerEdgeSchema.columns_hash['tinyint']
    end

    should 'be all it should be' do
      assert_equal :integer, @tinyint.type
      assert_nil @tinyint.scale
      assert_equal 'tinyint(1)', @tinyint.sql_type
    end

  end
  
  
end
