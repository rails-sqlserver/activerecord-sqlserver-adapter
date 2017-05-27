require 'support/paths_sqlserver'
require 'bundler/setup'
Bundler.require :default, :development
require 'pry'
require 'support/minitest_sqlserver'
require 'support/test_in_memory_oltp'
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
            ARTest::SQLServer::ConnectionReflection,
            ARTest::SQLServer::SqlCounterSqlserver,
            ActiveSupport::Testing::Stream

    let(:logger) { ActiveRecord::Base.logger }

    setup :ensure_clean_rails_env

    private

    def ensure_clean_rails_env
      Rails.instance_variable_set(:@_env, nil) if defined?(::Rails)
    end

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
