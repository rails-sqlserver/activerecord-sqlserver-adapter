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
    
    context 'dealing with various orders SQL snippets' do
      
      setup do
        @single_order = 'comments.id'
        @single_order_with_desc = 'comments.id DESC'
        @two_orders = 'comments.id, comments.post_id'
        @two_orders_with_asc = 'comments.id, comments.post_id ASC'
        @two_orders_with_desc_and_asc = 'comments.id DESC, comments.post_id ASC'
        @two_duplicate_order_with_dif_dir = "id, id DESC"
      end
      
      should 'convert to an 2D array of column/direction arrays using #orders_and_dirs_set' do
        assert_equal [['comments.id',nil]], orders_and_dirs_set('ORDER BY comments.id'), 'Needs to remove ORDER BY'
        assert_equal [['comments.id',nil]], orders_and_dirs_set(@single_order)
        assert_equal [['comments.id',nil],['comments.post_id',nil]], orders_and_dirs_set(@two_orders)
        assert_equal [['comments.id',nil],['comments.post_id','ASC']], orders_and_dirs_set(@two_orders_with_asc)
        assert_equal [['id',nil],['id','DESC']], orders_and_dirs_set(@two_duplicate_order_with_dif_dir)
      end
      
      should 'remove duplicate or maintain the same order by statements giving precedence to first using #add_order! method chain extension' do
        assert_equal 'ORDER BY comments.id', add_order!(@single_order)
        assert_equal 'ORDER BY comments.id DESC', add_order!(@single_order_with_desc)
        assert_equal 'ORDER BY comments.id, comments.post_id', add_order!(@two_orders)
        assert_equal 'ORDER BY comments.id DESC, comments.post_id ASC', add_order!(@two_orders_with_desc_and_asc)
        assert_equal 'ORDER BY id', add_order!(@two_duplicate_order_with_dif_dir)
      end
      
      should 'take all types of order options and convert them to MIN functions using #order_to_min_set' do
        assert_equal 'MIN(comments.id)', order_to_min_set(@single_order)
        assert_equal 'MIN(comments.id), MIN(comments.post_id)', order_to_min_set(@two_orders)
        assert_equal 'MIN(comments.id) DESC', order_to_min_set(@single_order_with_desc)
        assert_equal 'MIN(comments.id), MIN(comments.post_id) ASC', order_to_min_set(@two_orders_with_asc)
        assert_equal 'MIN(comments.id) DESC, MIN(comments.post_id) ASC', order_to_min_set(@two_orders_with_desc_and_asc)
      end
      
    end
    
    context 'with different language' do

      teardown do
        @connection.execute("SET LANGUAGE us_english") rescue nil
      end

      should_eventually 'do a date insertion when language is german' do
        @connection.execute("SET LANGUAGE deutsch")
        assert_nothing_raised do
          Task.create(:starting => Time.utc(2000, 1, 31, 5, 42, 0), :ending => Date.new(2006, 12, 31))
        end
      end

    end
    
  end
  
  context 'For chronic data types' do
    
    context 'with a usec' do

      setup do
        @time = Time.now
      end
      
      should 'truncate 123456 usec to just 123' do
        @time.stubs(:usec).returns(123456)
        saved = SqlServerChronic.create!(:datetime => @time).reload
        assert_equal 123000, saved.datetime.usec
      end
      
      should 'drop 123 to 0' do
        @time.stubs(:usec).returns(123)
        saved = SqlServerChronic.create!(:datetime => @time).reload
        assert_equal 0, saved.datetime.usec
        assert_equal '000', saved.datetime_before_type_cast.split('.').last
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
  
  context 'When disableing referential integrity' do
    
    setup do
      @parent = FkTestHasPk.create!
      @member = FkTestHasFk.create!(:fk_id => @parent.id)
    end
    
    should 'NOT ALLOW by default the deletion of a referenced parent' do
      assert_raise(ActiveRecord::StatementInvalid) { @parent.destroy }
    end
    
    should 'ALLOW deletion of referenced parent using #disable_referential_integrity block' do
      assert_nothing_raised(ActiveRecord::StatementInvalid) do
        FkTestHasPk.connection.disable_referential_integrity { @parent.destroy }
      end
    end
    
    should 'again NOT ALLOW deletion of referenced parent after #disable_referential_integrity block' do
      assert_raise(ActiveRecord::StatementInvalid) do
        FkTestHasPk.connection.disable_referential_integrity { }
        @parent.destroy
      end
    end
    
  end
  
  context 'For DatabaseStatements' do
    
  end
  
  context 'For SchemaStatements' do
    
    context 'returning from #type_to_sql' do
      
      should 'create integers when no limit supplied' do
        assert_equal 'integer', @connection.type_to_sql(:integer)
      end
      
      should 'create integers when limit is 4' do
        assert_equal 'integer', @connection.type_to_sql(:integer, 4)
      end
      
      should 'create integers when limit is 3' do
        assert_equal 'integer', @connection.type_to_sql(:integer, 3)
      end
      
      should 'create smallints when limit is less than 3' do
        assert_equal 'smallint', @connection.type_to_sql(:integer, 2)
        assert_equal 'smallint', @connection.type_to_sql(:integer, 1)
      end
      
      should 'create bigints when limit is greateer than 4' do
        assert_equal 'bigint', @connection.type_to_sql(:integer, 5)
        assert_equal 'bigint', @connection.type_to_sql(:integer, 6)
        assert_equal 'bigint', @connection.type_to_sql(:integer, 7)
        assert_equal 'bigint', @connection.type_to_sql(:integer, 8)
      end
      
    end
    
  end
  
  context 'For indexes' do
    
    setup do
      @desc_index_name = 'idx_credit_limit_test_desc'
      @connection.execute "CREATE INDEX #{@desc_index_name} ON accounts (credit_limit DESC)"
    end
    
    teardown do
      @connection.execute "DROP INDEX accounts.#{@desc_index_name}"
    end
    
    should 'have indexes with descending order' do
      assert @connection.indexes('accounts').detect { |i| i.name == @desc_index_name }
    end
    
  end
  
  
  private
  
  def orders_and_dirs_set(order)
    @connection.send :orders_and_dirs_set, order
  end
  
  def add_order!(order)
    sql = ''
    ActiveRecord::Base.send :add_order!, sql, order, nil
    sql
  end
  
  def order_to_min_set(order)
    @connection.send :order_to_min_set, order
  end
  
end

