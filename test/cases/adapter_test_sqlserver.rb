require 'cases/sqlserver_helper'
require 'models/task'
require 'models/topic'
require 'models/reply'
require 'models/joke'
require 'models/subscriber'

class AdapterTestSqlserver < ActiveRecord::TestCase
    
  def setup
    @connection = ActiveRecord::Base.connection
    @basic_insert_sql = "INSERT INTO [funny_jokes] ([name]) VALUES('Knock knock')"
    @basic_update_sql = "UPDATE [customers] SET [address_street] = NULL WHERE [id] = 2"
    @basic_select_sql = "SELECT * FROM [customers] WHERE ([customers].[id] = 1)"
  end
  
  context 'For abstract behavior' do
    
    should 'have a 128 max #table_alias_length' do
      assert @connection.table_alias_length <= 128
    end
    
    should 'raise invalid statement error' do
      assert_raise(ActiveRecord::StatementInvalid) { Topic.connection.update("UPDATE XXX") }
    end
    
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
    
    should 'return true to #insert_sql? for inserts only' do
      assert @connection.send(:insert_sql?,'INSERT...')
      assert !@connection.send(:insert_sql?,'UPDATE...')
      assert !@connection.send(:insert_sql?,'SELECT...')
    end
    
    context 'for #get_table_name' do

      should 'return quoted table name from basic INSERT, UPDATE and SELECT statements' do
        assert_equal '[funny_jokes]', @connection.send(:get_table_name,@basic_insert_sql)
        assert_equal '[customers]', @connection.send(:get_table_name,@basic_update_sql)
        assert_equal '[customers]', @connection.send(:get_table_name,@basic_select_sql)
      end

    end
    
    context 'with different language' do

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
    
  end
  
  context 'For identity inserts' do
    
    setup do
      @identity_insert_sql = "INSERT INTO [funny_jokes] ([id],[name]) VALUES(420,'Knock knock')"
    end
    
    should 'return quoted table_name to #query_requires_identity_insert? when INSERT sql contains id_column' do
      assert_equal '[funny_jokes]', @connection.send(:query_requires_identity_insert?,@identity_insert_sql)
    end
    
    should 'return false to #query_requires_identity_insert? for normal SQL' do
      [@basic_insert_sql, @basic_update_sql, @basic_select_sql].each do |sql|
        assert !@connection.send(:query_requires_identity_insert?,sql), "SQL was #{sql}"
      end
    end
    
    should 'find identity column using #identity_column' do
      joke_id_column = Joke.columns.detect { |c| c.name == 'id' }
      assert_equal joke_id_column, @connection.send(:identity_column,Joke.table_name)
    end
    
    should 'return nil when calling #identity_column for a table_name with no identity' do
      assert_nil @connection.send(:identity_column,Subscriber.table_name)
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
    
    should 'quote column names with brackets' do
      assert_equal '[foo]', @connection.quote_column_name(:foo)
      assert_equal '[foo]', @connection.quote_column_name('foo')
      assert_equal '[foo].[bar]', @connection.quote_column_name('foo.bar')
    end
    
    should 'quote table names like columns' do
      assert_equal '[foo].[bar]', @connection.quote_column_name('foo.bar')
      assert_equal '[foo].[bar].[baz]', @connection.quote_column_name('foo.bar.baz')
    end
    
  end
  
  context 'For DatabaseStatements' do
    
  end
  
  context 'For SchemaStatements' do
    
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
  
  
end

