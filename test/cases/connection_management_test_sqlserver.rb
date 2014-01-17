require "cases/sqlserver_helper"
require "rack"

module ActiveRecord
  module ConnectionAdapters
    class ConnectionManagementTest < ActiveRecord::TestCase

    COERCED_TESTS = [:test_connection_pool_per_pid]
    # Until that patch is made to rails we are preventing this test from running in this gem.

    include SqlserverCoercedTest

    #https://www.ruby-forum.com/topic/4221299
    def test_coerced_connection_pool_per_pid
        return skip('must support fork') unless Process.respond_to?(:fork)

        object_id = ActiveRecord::Base.connection.object_id

        rd, wr = IO.pipe

        # #https://www.ruby-forum.com/topic/4221299
        # puts "rd.internal_encoding:#{rd.internal_encoding}\nrd.external_encoding:#{rd.external_encoding}"
        # puts "wr.internal_encoding:#{wr.internal_encoding}\nwr.external_encoding:#{wr.external_encoding}"
        # # rd.internal_encoding:
        # # rd.external_encoding:UTF-8
        # # wr.internal_encoding:
        # # wr.external_encoding:UTF-8


        rd.binmode
        wr.binmode

        #       ERROR
        # marshal data too short
        # test/cases/connection_management_test_sqlserver.rb:43:in `load'
        # test/cases/connection_management_test_sqlserver.rb:43:in `test_coerced_connection_pool_per_pid'


        # /Users/acarey/code/nextgear/sqlserver/annaswims/activerecord-sqlserver-adapter/test/cases/connection_management_test_sqlserver.rb:41:in `write': "\x98" from ASCII-8BIT to UTF-8 (Encoding::UndefinedConversionError)
        #   from /Users/acarey/code/nextgear/sqlserver/annaswims/activerecord-sqlserver-adapter/test/cases/connection_management_test_sqlserver.rb:41:in `block in test_coerced_connection_pool_per_pid'
        #   from /Users/acarey/code/nextgear/sqlserver/annaswims/activerecord-sqlserver-adapter/test/cases/connection_management_test_sqlserver.rb:38:in `fork'
        #   from /Users/acarey/code/nextgear/sqlserver/annaswims/activerecord-sqlserver-adapter/test/cases/connection_management_test_sqlserver.rb:38:in `test_coerced_connection_pool_per_pid'
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
