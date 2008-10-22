require 'cases/sqlserver_helper'
require 'models/topic' 
require 'models/reply' 

class ConnectionTestSqlserver < ActiveRecord::TestCase
  
  self.use_transactional_fixtures = false
  
  fixtures :topics
  
  def setup
    @connection = ActiveRecord::Base.connection
  end
  
  
  def test_affected_rows
    assert Topic.connection.instance_variable_get("@connection")["AutoCommit"]
    topic_data = { 1 => { "content" => "1 updated" }, 2 => { "content" => "2 updated" } }
    updated = Topic.update(topic_data.keys, topic_data.values)
    assert_equal 2, updated.size
    assert_equal "1 updated", Topic.find(1).content
    assert_equal "2 updated", Topic.find(2).content
    assert_equal 2, Topic.delete([1, 2])        
  end
  
  def test_execute_without_block_closes_statement
    assert_all_statements_used_are_closed do
      @connection.execute("SELECT 1")
    end
  end

  def test_execute_with_block_closes_statement
    assert_all_statements_used_are_closed do
      @connection.execute("SELECT 1") do |sth|
        assert !sth.finished?, "Statement should still be alive within block"
      end
    end
  end

  def test_insert_with_identity_closes_statement
    assert_all_statements_used_are_closed do
      @connection.insert("INSERT INTO accounts ([id], [firm_id],[credit_limit]) values (999, 1, 50)")
    end
  end

  def test_insert_without_identity_closes_statement
    assert_all_statements_used_are_closed do
      @connection.insert("INSERT INTO accounts ([firm_id],[credit_limit]) values (1, 50)")
    end
  end

  def test_active_closes_statement
    assert_all_statements_used_are_closed do
      @connection.active?
    end
  end
  
  
  private
  
  def assert_all_statements_used_are_closed(&block)
    existing_handles = []
    ObjectSpace.each_object(DBI::StatementHandle) {|handle| existing_handles << handle}
    GC.disable
    yield
    used_handles = []
    ObjectSpace.each_object(DBI::StatementHandle) {|handle| used_handles << handle unless existing_handles.include? handle}
    assert_block "No statements were used within given block" do
      used_handles.size > 0
    end
    ObjectSpace.each_object(DBI::StatementHandle) do |handle|
      assert_block "Statement should have been closed within given block" do
        handle.finished?
      end
    end
  ensure
    GC.enable
  end

end
