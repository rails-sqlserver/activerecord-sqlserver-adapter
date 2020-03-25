require 'cases/helper_sqlserver'
require 'models/reply'
require 'models/topic'

class ConnectionTestSQLServer < ActiveRecord::TestCase

  self.use_transactional_tests = false

  fixtures :topics, :accounts

  before do
    connection.reconnect!
    assert connection.active?
  end

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
  end unless connection_sqlserver_azure?

  describe 'Connection management' do

    it 'set spid on connect' do
      _(['Fixnum', 'Integer']).must_include connection.spid.class.name
    end

    it 'reset spid on disconnect!' do
      connection.disconnect!
      assert connection.spid.nil?
    end

    it 'reset the connection' do
      connection.disconnect!
      _(connection.raw_connection).must_be_nil
    end

    it 'be able to disconnect and reconnect at will' do
      disconnect_raw_connection!
      assert !connection.active?
      connection.reconnect!
      assert connection.active?
    end

  end


  private

  def disconnect_raw_connection!
    case connection_options[:mode]
    when :dblib
      connection.raw_connection.close rescue nil
    end
  end

end
