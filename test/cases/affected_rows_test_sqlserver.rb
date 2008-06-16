require 'cases/helper' 
require 'models/topic' 
require 'models/reply' 

class AffectedRowsTestSqlserver < ActiveRecord::TestCase
  self.use_transactional_fixtures = false
  fixtures :topics

  def setup
    @first, @second = Topic.find(1, 2).sort_by { |t| t.id }
  end

  def test_affected_rows
    assert Topic.connection.instance_variable_get("@connection")["AutoCommit"]

    topic_data = { 1 => { "content" => "1 updated" }, 2 => { "content" => "2 updated" } }
    updated = Topic.update(topic_data.keys, topic_data.values)

    assert_equal 2, updated.size
    assert_equal "1 updated", Topic.find(1).content
    assert_equal "2 updated", Topic.find(2).content
  
    assert_equal 2, Topic.delete_all        
  end
  
  def test_update_sql_statement_invalid
    assert_raise(ActiveRecord::StatementInvalid) { Topic.connection.update_sql("UPDATE XXX") }
  end
end
