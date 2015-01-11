require 'bundler' ; Bundler.require :default, :development, :test
require 'support/paths_sqlserver'
require 'support/minitest_sqlserver'
require 'cases/helper'
require 'support/load_schema_sqlserver'
require 'support/coerced_test_sqlserver'
require 'support/sql_counter_sqlserver'
require 'mocha/mini_test'

module ActiveRecord
  class TestCase < ActiveSupport::TestCase

    class << self
      def connection_mode_dblib? ; ActiveRecord::Base.connection.instance_variable_get(:@connection_options)[:mode] == :dblib ; end
      def connection_mode_odbc? ; ActiveRecord::Base.connection.instance_variable_get(:@connection_options)[:mode] == :odbc ; end
      def sqlserver_2005? ; ActiveRecord::Base.connection.sqlserver_2005? ; end
      def sqlserver_2008? ; ActiveRecord::Base.connection.sqlserver_2008? ; end
      def sqlserver_azure? ; ActiveRecord::Base.connection.sqlserver_azure? ; end
    end

    def connection_mode_dblib? ; self.class.connection_mode_dblib? ; end
    def connection_mode_odbc? ; self.class.connection_mode_odbc? ; end
    def sqlserver_2005? ; self.class.sqlserver_2005? ; end
    def sqlserver_2008? ; self.class.sqlserver_2008? ; end
    def sqlserver_azure? ; self.class.sqlserver_azure? ; end

    def with_enable_default_unicode_types?
      ActiveRecord::ConnectionAdapters::SQLServerAdapter.enable_default_unicode_types.is_a?(TrueClass)
    end

    def with_enable_default_unicode_types(setting)
      old_setting = ActiveRecord::ConnectionAdapters::SQLServerAdapter.enable_default_unicode_types
      old_text = ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_text_database_type
      old_string = ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_string_database_type
      ActiveRecord::ConnectionAdapters::SQLServerAdapter.enable_default_unicode_types = setting
      ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_text_database_type = nil
      ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_string_database_type = nil
      yield
    ensure
      ActiveRecord::ConnectionAdapters::SQLServerAdapter.enable_default_unicode_types = old_setting
      ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_text_database_type = old_text
      ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_string_database_type = old_string
    end

    def with_auto_connect(boolean)
      existing = ActiveRecord::ConnectionAdapters::SQLServerAdapter.auto_connect
      ActiveRecord::ConnectionAdapters::SQLServerAdapter.auto_connect = boolean
      yield
    ensure
      ActiveRecord::ConnectionAdapters::SQLServerAdapter.auto_connect = existing
    end

  end
end

Dir["#{ARTest::SQLServer.test_root_sqlserver}/models/**/*.rb"].each { |f| require f }
