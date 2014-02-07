#This rails pull request will make this code unnecessary https://github.com/rails/rails/pull/13745

require "cases/sqlserver_helper"
require "rack"

module ActiveRecord
  module ConnectionAdapters
    class ConnectionManagementTest < ActiveRecord::TestCase

    COERCED_TESTS = [:test_connection_pool_per_pid]

    include SqlserverCoercedTest

    #https://www.ruby-forum.com/topic/4221299
    def test_coerced_connection_pool_per_pid
        return skip('must support fork') unless Process.respond_to?(:fork)

        object_id = ActiveRecord::Base.connection.object_id

        rd, wr = IO.pipe
        rd.binmode
        wr.binmode
        pid = fork {
          rd.close
          wr.write Marshal.dump ActiveRecord::Base.connection.object_id
          wr.close
          exit!
        }

        wr.close

        Process.waitpid pid
        assert_not_equal object_id, Marshal.load(rd.read)
        rd.close
      end
    end
  end
end
