require 'cases/sqlserver_helper'
require 'models/topic'
require 'models_sqlserver/topic'

class BindParameterTestSqlServer < ActiveRecord::TestCase

  COERCED_TESTS = [
    :test_binds_are_logged,
    :test_binds_are_logged_after_type_cast
  ]

  include SqlserverCoercedTest

  fixtures :topics

  class LogListener
    attr_accessor :calls

    def initialize
      @calls = []
    end

    def call(*args)
      calls << args
    end
  end

  def setup
    super
    @connection = ActiveRecord::Base.connection
    @listener   = LogListener.new
    @pk         = Topic.columns.find { |c| c.primary }
    ActiveSupport::Notifications.subscribe('sql.active_record', @listener)
  end

  def teardown
    ActiveSupport::Notifications.unsubscribe(@listener)
  end

  def test_coerced_binds_are_logged
    sub   = @connection.substitute_at(@pk, 0)
    binds = [[@pk, 1]]
    sql   = "select * from topics where id = #{sub}"

    @connection.exec_query(sql, 'SQL', binds)

    message = @listener.calls.find { |args| args[4][:sql].include? sql }
    assert_equal binds, message[4][:binds]
  end

  def test_coerced_binds_are_logged_after_type_cast
    sub   = @connection.substitute_at(@pk, 0)
    binds = [[@pk, "3"]]
    sql   = "select * from topics where id = #{sub}"

    @connection.exec_query(sql, 'SQL', binds)

    message = @listener.calls.find { |args| args[4][:sql].include? sql }
    assert_equal [[@pk, 3]], message[4][:binds]
  end

end
