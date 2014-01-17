SQLSERVER_TEST_ROOT       = File.expand_path(File.join(File.dirname(__FILE__),'..'))
SQLSERVER_ASSETS_ROOT     = File.expand_path(File.join(SQLSERVER_TEST_ROOT,'assets'))
SQLSERVER_FIXTURES_ROOT   = File.expand_path(File.join(SQLSERVER_TEST_ROOT,'fixtures'))
SQLSERVER_MIGRATIONS_ROOT = File.expand_path(File.join(SQLSERVER_TEST_ROOT,'migrations'))
SQLSERVER_SCHEMA_ROOT     = File.expand_path(File.join(SQLSERVER_TEST_ROOT,'schema'))
ACTIVERECORD_TEST_ROOT    = File.expand_path(File.join(Gem.loaded_specs['activerecord'].full_gem_path,'test'))

ENV['ARCONFIG']           = File.expand_path(File.join(SQLSERVER_TEST_ROOT,'config.yml'))

$LOAD_PATH.unshift ACTIVERECORD_TEST_ROOT

require 'rubygems'
require 'bundler'
Bundler.setup
require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end
require 'pry'
require 'graphviz'
require 'mocha/api'
require 'active_support/dependencies'
require 'active_record'
require 'active_record/version'
require 'active_record/connection_adapters/abstract_adapter'
require 'minitest-spec-rails'
require 'minitest-spec-rails/init/active_support'
require 'minitest-spec-rails/init/mini_shoulda'
require 'cases/helper'
require 'models/topic'
require 'cases/arel_helper'
require 'cases/sqlserver_test_case'

GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly?)

ActiveRecord::Migration.verbose = false
ActiveRecord::Base.logger = Logger.new(File.expand_path(File.join(SQLSERVER_TEST_ROOT,'debug.log')))
ActiveRecord::Base.logger.level = 0


# A module that we can include in classes where we want to override an active record test.

module SqlserverCoercedTest
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def self.extended(base)
      base.class_eval do
        Array(coerced_tests).each do |method_name|
          undefine_and_puts(method_name)
        end
      end
    end

    def coerced_tests
      self.const_get(:COERCED_TESTS) rescue nil
    end

    def method_added(method)
      if coerced_tests && coerced_tests.include?(method)
        undefine_and_puts(method)
      end
    end

    def undefine_and_puts(method)
      result = undef_method(method) rescue nil
      STDOUT.puts("Info: Undefined coerced test: #{self.name}##{method}") unless result.blank?
    end

  end
end

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

# Core AR.
schema_file = "#{ACTIVERECORD_TEST_ROOT}/schema/schema.rb"
eval(File.read(schema_file))

# SQL Server.
sqlserver_specific_schema_file = "#{SQLSERVER_SCHEMA_ROOT}/sqlserver_specific_schema.rb"
eval(File.read(sqlserver_specific_schema_file))
