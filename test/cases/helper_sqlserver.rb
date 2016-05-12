require 'support/paths_sqlserver'
require 'bundler/setup'
Bundler.require :default, :development
require 'support/minitest_sqlserver'
require 'cases/helper'
require 'support/load_schema_sqlserver'
require 'support/coerceable_test_sqlserver'
require 'support/sql_counter_sqlserver'
require 'support/connection_reflection'
require 'mocha/mini_test'

module ActiveRecord
  class TestCase < ActiveSupport::TestCase

    SQLServer = ActiveRecord::ConnectionAdapters::SQLServer

    include ARTest::SQLServer::CoerceableTest,
            ARTest::SQLServer::ConnectionReflection

    let(:logger) { ActiveRecord::Base.logger }


    private

    def host_windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
    end

    def with_use_output_inserted_disabled
      klass = ActiveRecord::ConnectionAdapters::SQLServerAdapter
      klass.use_output_inserted = false
      yield
    ensure
      klass.use_output_inserted = true
    end

    def silence_stream(stream)
      old_stream = stream.dup
      stream.reopen(RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ? 'NUL:' : '/dev/null')
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
      old_stream.close
    end

    def quietly
      silence_stream(STDOUT) { silence_stream(STDERR) { yield } }
    end

  end
end

Dir["#{ARTest::SQLServer.test_root_sqlserver}/models/**/*.rb"].each { |f| require f }
