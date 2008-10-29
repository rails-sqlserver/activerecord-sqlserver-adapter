require 'cases/sqlserver_helper'
require 'models/task'
require 'models/topic'

class AdapterTestSqlserver < ActiveRecord::TestCase
    
  def setup
    @connection = ActiveRecord::Base.connection
  end
  
  context 'For abstract behavior' do

    should 'be our adapter_name' do
      assert_equal 'SQLServer', @connection.adapter_name
    end
    
    should 'support migrations' do
      assert @connection.supports_migrations?
    end
    
    should 'support DDL in transactions' do
      assert @connection.supports_ddl_transactions?
    end
    
    context 'for database version' do
      
      setup do
        @version_regexp = ActiveRecord::ConnectionAdapters::SQLServerAdapter::DATABASE_VERSION_REGEXP
        @supported_version = ActiveRecord::ConnectionAdapters::SQLServerAdapter::SUPPORTED_VERSIONS
        @sqlserver_2000_string = "Microsoft SQL Server  2000 - 8.00.2039 (Intel X86)"
        @sqlserver_2005_string = "Microsoft SQL Server 2005 - 9.00.3215.00 (Intel X86)"
      end
      
      should 'return a string from #database_version that matches class regexp' do
        assert_match @version_regexp, @connection.database_version
      end
      
      should 'return a 4 digit year fixnum for #database_year' do
        assert_instance_of Fixnum, @connection.database_year
        assert_contains @supported_version, @connection.database_year
      end
      
      should 'return true to #sqlserver_2000?' do
        @connection.stubs(:database_version).returns(@sqlserver_2000_string)
        assert @connection.sqlserver_2000?
      end
      
      should 'return true to #sqlserver_2005?' do
        @connection.stubs(:database_version).returns(@sqlserver_2005_string)
        assert @connection.sqlserver_2005?
      end
      
    end
    
    context 'for #unqualify_table_name and #unqualify_db_name' do

      setup do
        @expected_table_name = 'baz'
        @expected_db_name = 'foo'
        @first_second_table_names = ['[baz]','baz','[bar].[baz]','bar.baz']
        @third_table_names = ['[foo].[bar].[baz]','foo.bar.baz']
        @qualifed_table_names = @first_second_table_names + @third_table_names
      end
      
      should 'return clean table_name from #unqualify_table_name' do
        @qualifed_table_names.each do |qtn|
          assert_equal @expected_table_name, 
            @connection.send(:unqualify_table_name,qtn),
            "This qualifed_table_name #{qtn} did not unqualify correctly."
        end
      end
      
      should 'return nil from #unqualify_db_name when table_name is less than 2 qualified' do
        @first_second_table_names.each do |qtn|
          assert_equal nil, @connection.send(:unqualify_db_name,qtn),
            "This qualifed_table_name #{qtn} did not return nil."
        end
      end
      
      should 'return clean db_name from #unqualify_db_name when table is thrid level qualified' do
        @third_table_names.each do |qtn|
          assert_equal @expected_db_name, 
            @connection.send(:unqualify_db_name,qtn),
            "This qualifed_table_name #{qtn} did not unqualify the db_name correctly."
        end
      end

    end
    
  end
  
  context 'For identity inserts' do
    
    setup do
      @identity_insert_sql = "INSERT INTO [funny_jokes] ([id],[name]) VALUES(420,'Knock knock')"
    end
    
    should 'return true to #query_requires_identity_insert? when INSERT sql contains id_column ' do
      assert @connection.send(:query_requires_identity_insert?,@identity_insert_sql)
    end
    
    should 'return false to #query_requires_identity_insert? for normal SQL' do
      insert_sql = "INSERT INTO [funny_jokes] ([name]) VALUES('Knock knock')"
      update_sql = "UPDATE [customers] SET [address_street] = NULL WHERE [id] = 2"
      select_sql = "SELECT * FROM [customers] WHERE ([customers].[id] = 1)"
      [insert_sql,update_sql,select_sql].each do |sql|
        assert !@connection.send(:query_requires_identity_insert?,sql), "SQL was #{sql}"
      end
    end
    
  end
  
  context 'For Quoting' do
    
    should 'return 1 for #quoted_true' do
      assert_equal '1', @connection.quoted_true
    end
    
    should 'return 0 for #quoted_false' do
      assert_equal '0', @connection.quoted_false
    end
    
    should 'not escape backslash characters like abstract adapter' do
      string_with_backslashs = "\\n"
      assert_equal string_with_backslashs, @connection.quote_string(string_with_backslashs)
    end
    
  end
  
  context 'For DatabaseStatements' do
    
  end
  
  context 'For SchemaStatements' do
    
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

