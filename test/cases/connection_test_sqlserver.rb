require 'cases/helper_sqlserver'
require 'models/reply'
require 'models/topic'

class ConnectionTestSQLServer < ActiveRecord::TestCase

  self.use_transactional_fixtures = false

  fixtures :topics, :accounts

  before { assert connection.active? }
  after  { connection.reconnect! }

  it 'affect rows' do
    topic_data = { 1 => { "content" => "1 updated" }, 2 => { "content" => "2 updated" } }
    updated = Topic.update(topic_data.keys, topic_data.values)
    assert_equal 2, updated.size
    assert_equal "1 updated", Topic.find(1).content
    assert_equal "2 updated", Topic.find(2).content
    assert_equal 2, Topic.delete([1, 2])
  end

  it 'allow usage of :database connection option to remove setting from dsn' do
    assert_equal 'activerecord_unittest', connection.current_database
    begin
      connection.use_database('activerecord_unittest2')
      assert_equal 'activerecord_unittest2', connection.current_database
    ensure
      connection.use_database
      assert_equal 'activerecord_unittest', connection.current_database, 'Would default back to connection options'
    end
  end unless sqlserver_azure?

  describe 'ODBC connection management' do

    it 'return finished ODBC statement handle from #execute without block' do
      assert_all_odbc_statements_used_are_closed do
        connection.execute('SELECT * FROM [topics]')
      end
    end

    it 'finish ODBC statement handle from #execute with block' do
      assert_all_odbc_statements_used_are_closed do
        connection.execute('SELECT * FROM [topics]') { }
      end
    end

    it 'finish connection from #raw_select' do
      assert_all_odbc_statements_used_are_closed do
        connection.send(:raw_select,'SELECT * FROM [topics]')
      end
    end

    it 'execute without block closes statement' do
      assert_all_odbc_statements_used_are_closed do
        connection.execute("SELECT 1")
      end
    end

    it 'execute with block closes statement' do
      assert_all_odbc_statements_used_are_closed do
        connection.execute("SELECT 1") do |sth|
          assert !sth.finished?, "Statement should still be alive within block"
        end
      end
    end

    it 'insert with identity closes statement' do
      assert_all_odbc_statements_used_are_closed do
        connection.exec_insert "INSERT INTO accounts ([id],[firm_id],[credit_limit]) VALUES (999, 1, 50)", "SQL", []
      end
    end

    it 'insert without identity closes statement' do
      assert_all_odbc_statements_used_are_closed do
        connection.exec_insert "INSERT INTO accounts ([firm_id],[credit_limit]) VALUES (1, 50)", "SQL", []
      end
    end

    it 'active closes statement' do
      assert_all_odbc_statements_used_are_closed do
        connection.active?
      end
    end

  end if connection_mode_odbc?


  describe 'Connection management' do

    it 'set spid on connect' do
      assert_instance_of Fixnum, connection.spid
    end

    it 'reset spid on disconnect!' do
      connection.disconnect!
      assert connection.spid.nil?
    end

    it 'reset the connection' do
      connection.disconnect!
      connection.raw_connection.must_be_nil
    end

    it 'be able to disconnect and reconnect at will' do
      disconnect_raw_connection!
      assert !connection.active?
      connection.reconnect!
      assert connection.active?
    end

    it 'auto reconnect when setting is on' do
      with_auto_connect(true) do
        disconnect_raw_connection!
        assert_nothing_raised() { Topic.count }
        assert connection.active?
      end
    end

    it 'not auto reconnect when setting is off' do
      with_auto_connect(false) do
        disconnect_raw_connection!
        assert_raise(ActiveRecord::LostConnection) { Topic.count }
      end
    end

    it 'not auto reconnect on commit transaction' do
      disconnect_raw_connection!
      assert_raise(ActiveRecord::LostConnection) { connection.commit_db_transaction }
    end

    it 'gracefully ignore lost connections on rollback transaction' do
      disconnect_raw_connection!
      assert_nothing_raised { connection.rollback_db_transaction }
    end

    describe 'testing #disable_auto_reconnect' do

      it 'when auto reconnect setting is on' do
        with_auto_connect(true) do
          connection.send(:disable_auto_reconnect) do
            assert !connection.class.auto_connect
          end
          assert connection.class.auto_connect
        end
      end

      it 'when auto reconnect setting is off' do
        with_auto_connect(false) do
          connection.send(:disable_auto_reconnect) do
            assert !connection.class.auto_connect
          end
          assert !connection.class.auto_connect
        end
      end

    end

    describe 'with a deadlock victim exception 1205' do

      describe 'outside a transaction' do

        before do
          @query = "SELECT 1 as [one]"
          @expected = connection.execute(@query)
          # Execute the query to get a handle of the expected result, which
          # will be returned after a simulated deadlock victim (1205).
          raw_conn = connection.raw_connection
          stubbed_handle = raw_conn.execute(@query)
          connection.send(:finish_statement_handle, stubbed_handle)
          raw_conn.stubs(:execute).raises(deadlock_victim_exception(@query)).then.returns(stubbed_handle)
        end

        it 'raise ActiveRecord::DeadlockVictim' do
          assert_raise(ActiveRecord::DeadlockVictim) do
            assert_equal @expected, connection.execute(@query)
          end
        end

      end

      describe 'within a transaction' do

        before do
          @query = "SELECT 1 as [one]"
          @expected = connection.execute(@query)
          # We "stub" the execute method to simulate raising a deadlock victim exception once.
          connection.class.class_eval do
            def execute_with_deadlock_exception(sql, *args)
              if !@raised_deadlock_exception && sql == "SELECT 1 as [one]"
                sql = "RAISERROR('Transaction (Process ID #{Process.pid}) was deadlocked on lock resources with another process and has been chosen as the deadlock victim. Rerun the transaction.: #{sql}', 13, 1)"
                @raised_deadlock_exception = true
              elsif @raised_deadlock_exception == true && sql =~ /RAISERROR\('Transaction \(Process ID \d+\) was deadlocked on lock resources with another process and has been chosen as the deadlock victim\. Rerun the transaction\.: SELECT 1 as \[one\]', 13, 1\)/
                sql = "SELECT 1 as [one]"
              end
              execute_without_deadlock_exception(sql, *args)
            end
            alias :execute_without_deadlock_exception :execute
            alias :execute :execute_with_deadlock_exception
          end
        end

        after do
          # Cleanup the "stubbed" execute method.
          connection.class.class_eval do
            alias :execute :execute_without_deadlock_exception
            remove_method :execute_with_deadlock_exception
            remove_method :execute_without_deadlock_exception
          end
          connection.send(:remove_instance_variable, :@raised_deadlock_exception)
        end

        it 'raise ActiveRecord::DeadlockVictim if retry disabled' do
          assert_raise(ActiveRecord::DeadlockVictim) do
            ActiveRecord::Base.transaction do
              assert_equal @expected, connection.execute(@query)
            end
          end
        end

      end

    end if connection_mode_dblib? # Since it is easier to test, but feature should work in ODBC too.

  end


  private

  def disconnect_raw_connection!
    case connection.instance_variable_get(:@connection_options)[:mode]
    when :dblib
      connection.raw_connection.close rescue nil
    when :odbc
      connection.raw_connection.disconnect rescue nil
    end
  end

  def assert_all_odbc_statements_used_are_closed(&block)
    odbc = connection.raw_connection.class.parent
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

  def deadlock_victim_exception(sql)
    require 'tiny_tds/error'
    error = TinyTds::Error.new("Transaction (Process ID #{Process.pid}) was deadlocked on lock resources with another process and has been chosen as the deadlock victim. Rerun the transaction.: #{sql}")
    error.severity = 13
    error.db_error_number = 1205
    error
  end

end
