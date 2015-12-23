require 'bundler' ; Bundler.require :default, :development, :test
require 'support/paths_sqlserver'
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

  end
end

Dir["#{ARTest::SQLServer.test_root_sqlserver}/models/**/*.rb"].each { |f| require f }
