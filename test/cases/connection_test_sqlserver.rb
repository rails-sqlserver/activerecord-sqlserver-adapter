require 'cases/sqlserver_helper'
require 'models/reply' 

class ConnectionTestSqlserver < ActiveRecord::TestCase
  
  self.use_transactional_fixtures = false
  
  fixtures :topics, :accounts
  
  def setup
    @connection = ActiveRecord::Base.connection
  end
  
  should 'affect rows' do
    topic_data = { 1 => { "content" => "1 updated" }, 2 => { "content" => "2 updated" } }
    updated = Topic.update(topic_data.keys, topic_data.values)
    assert_equal 2, updated.size
    assert_equal "1 updated", Topic.find(1).content
    assert_equal "2 updated", Topic.find(2).content
    assert_equal 2, Topic.delete([1, 2])        
  end
  
  should 'allow usage of :database connection option to remove setting from dsn' do
    assert_equal 'activerecord_unittest', @connection.current_database
    begin
      @connection.use_database('activerecord_unittest2')
      assert_equal 'activerecord_unittest2', @connection.current_database
    ensure
      @connection.use_database
      assert_equal 'activerecord_unittest', @connection.current_database, 'Would default back to connection options'
    end
  end unless sqlserver_azure?
  
  context 'ODBC connection management' do

    should 'return finished ODBC statement handle from #execute without block' do
      assert_all_odbc_statements_used_are_closed do
        @connection.execute('SELECT * FROM [topics]')
      end
    end

    should 'finish ODBC statement handle from #execute with block' do
      assert_all_odbc_statements_used_are_closed do
        @connection.execute('SELECT * FROM [topics]') { }
      end
    end

    should 'finish connection from #raw_select' do
      assert_all_odbc_statements_used_are_closed do
        @connection.send(:raw_select,'SELECT * FROM [topics]')
      end
    end

    should 'execute without block closes statement' do
      assert_all_odbc_statements_used_are_closed do
        @connection.execute("SELECT 1")
      end
    end

    should 'execute with block closes statement' do
      assert_all_odbc_statements_used_are_closed do
        @connection.execute("SELECT 1") do |sth|
          assert !sth.finished?, "Statement should still be alive within block"
        end
      end
    end

    should 'insert with identity closes statement' do
      assert_all_odbc_statements_used_are_closed do
        @connection.exec_insert "INSERT INTO accounts ([id],[firm_id],[credit_limit]) VALUES (999, 1, 50)", "SQL", []
      end
    end

    should 'insert without identity closes statement' do
      assert_all_odbc_statements_used_are_closed do
        @connection.exec_insert "INSERT INTO accounts ([firm_id],[credit_limit]) VALUES (1, 50)", "SQL", []
      end
    end

    should 'active closes statement' do
      assert_all_odbc_statements_used_are_closed do
        @connection.active?
      end
    end

  end if connection_mode_odbc?
  
  
  context 'Connection management' do
    
    setup do
      assert @connection.active?
    end
    
    if connection_mode_dblib?
      should 'set spid on connect' do
        assert @connection.spid.kind_of?(Fixnum)
      end
    
      should 'reset spid on disconnect!' do
        @connection.disconnect!
        assert @connection.spid.nil?
      end
    end
    
    should 'be able to disconnect and reconnect at will' do
      @connection.disconnect!
      assert !@connection.active?
      @connection.reconnect!
      assert @connection.active?
    end
    
    should 'auto reconnect when setting is on' do
      with_auto_connect(true) do
        @connection.disconnect!
        assert_nothing_raised() { Topic.count }
        assert @connection.active?
      end
    end
    
    should 'not auto reconnect when setting is off' do
      with_auto_connect(false) do
        @connection.disconnect!
        assert_raise(ActiveRecord::LostConnection) { Topic.count }
      end
    end
    
    context 'testing #disable_auto_reconnect' do
      should 'when auto reconnect setting is on' do
        with_auto_connect(true) do
          @connection.send(:disable_auto_reconnect) do
            assert !@connection.class.auto_connect
          end
          assert @connection.class.auto_connect
        end
      end
      
      should 'when auto reconnect setting is off' do
        with_auto_connect(false) do
          @connection.send(:disable_auto_reconnect) do
            assert !@connection.class.auto_connect
          end
          assert !@connection.class.auto_connect
        end
      end
    end
    
    should 'not auto reconnect on commit transaction' do
      @connection.disconnect!
      assert_raise(ActiveRecord::LostConnection) { @connection.commit_db_transaction }
    end
    
    should 'gracefully ignore lost connections on rollback transaction' do
      @connection.disconnect!
      assert_nothing_raised { @connection.rollback_db_transaction }
    end
    
    should 'not auto reconnect on create savepoint' do
      @connection.disconnect!
      assert_raise(ActiveRecord::LostConnection) { @connection.create_savepoint }
    end
    
    should 'not auto reconnect on rollback to savepoint ' do
      @connection.disconnect!
      assert_raise(ActiveRecord::LostConnection) { @connection.rollback_to_savepoint }
    end
  end
  
  context 'Diagnostics' do
    should 'testing #activity_stats' do
      stats = @connection.activity_stats
      assert stats.length > 0
      
      assert stats.all? { |s| s.has_key?("session_id") }
      assert stats.all? { |s| s["database"] == @connection.current_database }
    end
  end
  
  
  
  private
  
  def assert_all_odbc_statements_used_are_closed(&block)
    odbc = @connection.raw_connection.class.parent
    existing_handles = []
    ObjectSpace.each_object(odbc::Statement) { |h| existing_handles << h }
    existing_handle_ids = existing_handles.map(&:object_id)
    assert existing_handles.all?(&:finished?), "Somewhere before the block some statements were not closed"
    GC.disable    
    yield
    used_handles = []
    ObjectSpace.each_object(odbc::Statement) { |h| used_handles << h unless existing_handle_ids.include?(h.object_id) }
    assert used_handles.size > 0, "No statements were used within given block"
    assert used_handles.all?(&:finished?), "Statement should have been closed within given block"
  ensure
    GC.enable
  end
  
  def with_auto_connect(boolean)
    existing = ActiveRecord::ConnectionAdapters::SQLServerAdapter.auto_connect
    ActiveRecord::ConnectionAdapters::SQLServerAdapter.auto_connect = boolean
    yield
  ensure
    ActiveRecord::ConnectionAdapters::SQLServerAdapter.auto_connect = existing
  end

end
