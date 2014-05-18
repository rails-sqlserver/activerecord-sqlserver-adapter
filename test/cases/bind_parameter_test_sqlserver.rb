require 'cases/sqlserver_helper'
require 'models/topic'
require 'models_sqlserver/topic'
require 'cases/bind_parameter_test'

# We don't coerce here because these tests are located inside of an if block
# and don't seem to be able to be properly overriden with the coerce
# functionality
module ActiveRecord
  class BindParameterTest
    def test_binds_are_logged
      sub   = @connection.substitute_at(@pk, 0)
      binds = [[@pk, 1]]
      sql   = "select * from topics where id = #{sub}"

      @connection.exec_query(sql, 'SQL', binds)

      message = @listener.calls.find { |args| args[4][:sql].include? sql }
      assert_equal binds, message[4][:binds]
    end

    def test_binds_are_logged_after_type_cast
      sub   = @connection.substitute_at(@pk, 0)
      binds = [[@pk, "3"]]
      sql   = "select * from topics where id = #{sub}"

      @connection.exec_query(sql, 'SQL', binds)

      message = @listener.calls.find { |args| args[4][:sql].include? sql }
      assert_equal [[@pk, 3]], message[4][:binds]
    end
  end
end
