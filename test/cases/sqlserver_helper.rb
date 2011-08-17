
SQLSERVER_TEST_ROOT       = File.expand_path(File.join(File.dirname(__FILE__),'..'))
SQLSERVER_ASSETS_ROOT     = File.expand_path(File.join(SQLSERVER_TEST_ROOT,'assets'))
SQLSERVER_FIXTURES_ROOT   = File.expand_path(File.join(SQLSERVER_TEST_ROOT,'fixtures'))
SQLSERVER_MIGRATIONS_ROOT = File.expand_path(File.join(SQLSERVER_TEST_ROOT,'migrations'))
SQLSERVER_SCHEMA_ROOT     = File.expand_path(File.join(SQLSERVER_TEST_ROOT,'schema'))
ACTIVERECORD_TEST_ROOT    = File.expand_path(File.join(Gem.loaded_specs['activerecord'].full_gem_path,'test'))
ENV['ARCONFIG']           = File.expand_path(File.join(SQLSERVER_TEST_ROOT,'config.yml'))

$:.unshift ACTIVERECORD_TEST_ROOT

require 'rubygems'
require 'bundler'
Bundler.setup
require 'shoulda'
require 'mocha'
require 'cases/helper'
require 'models/topic'
require 'active_record/version'

GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly?)

ActiveRecord::Migration.verbose = false
ActiveRecord::Base.logger = Logger.new(File.expand_path(File.join(SQLSERVER_TEST_ROOT,'debug.log')))
ActiveRecord::Base.logger.level = 0

# Defining our classes in one place as well as soem core tests that need coercing date/time types.

class UpperTestDefault < ActiveRecord::Base ; self.table_name = 'UPPER_TESTS' ; end
class UpperTestLowered < ActiveRecord::Base ; self.table_name = 'upper_tests' ; end
class TableWithRealColumn < ActiveRecord::Base; end
class FkTestHasFk < ActiveRecord::Base ; end
class FkTestHasPk < ActiveRecord::Base ; end
class NumericData < ActiveRecord::Base ; self.table_name = 'numeric_data' ; end
class CustomersView < ActiveRecord::Base ; self.table_name = 'customers_view' ; end
class StringDefaultsView < ActiveRecord::Base ; self.table_name = 'string_defaults_view' ; end
class StringDefaultsBigView < ActiveRecord::Base ; self.table_name = 'string_defaults_big_view' ; end
class SqlServerNaturalPkData < ActiveRecord::Base ; self.table_name = 'natural_pk_data' ; end
class SqlServerNaturalPkDataSchema < ActiveRecord::Base ; self.table_name = 'test.sql_server_schema_natural_id' ; end
class SqlServerQuotedTable < ActiveRecord::Base ; self.table_name = 'quoted-table' ; end
class SqlServerQuotedView1 < ActiveRecord::Base ; self.table_name = 'quoted-view1' ; end
class SqlServerQuotedView2 < ActiveRecord::Base ; self.table_name = 'quoted-view2' ; end
class SqlServerUnicode < ActiveRecord::Base ; end
class SqlServerString < ActiveRecord::Base ; end
class NoPkData < ActiveRecord::Base ; self.table_name = 'no_pk_data' ; end
class StringDefault < ActiveRecord::Base; end
class SqlServerEdgeSchema < ActiveRecord::Base
  attr_accessor :new_id_setting
  before_create :set_new_id
  protected
  def set_new_id
    self[:guid_newid] ||= connection.newid_function if new_id_setting
  end
end
class SqlServerChronic < ActiveRecord::Base
  coerce_sqlserver_date :date
  coerce_sqlserver_time :time
  default_timezone = :utc
end
class Topic < ActiveRecord::Base
  coerce_sqlserver_date :last_read
  coerce_sqlserver_time :bonus_time
end
class Person < ActiveRecord::Base
  coerce_sqlserver_date :favorite_day
end

# A module that we can include in classes where we want to override an active record test.

module SqlserverCoercedTest
  def self.included(base)
    base.extend ClassMethods
  end
  module ClassMethods
    def coerced_tests
      self.const_get(:COERCED_TESTS) rescue nil
    end
    def method_added(method)
      if coerced_tests && coerced_tests.include?(method)
        undef_method(method) rescue nil
        STDOUT.puts("Undefined coerced test: #{self.name}##{method}")
      end
    end
  end
end


# Our changes/additions to ActiveRecord test helpers specific for SQL Server.

module ActiveRecord
  class SQLCounter
    self.ignored_sql =  [ 
      %r|SELECT SCOPE_IDENTITY|, %r{INFORMATION_SCHEMA\.(TABLES|VIEWS|COLUMNS)},
      %r|SELECT @@version|, %r|SELECT @@TRANCOUNT|, %r{(BEGIN|COMMIT|ROLLBACK|SAVE) TRANSACTION}
    ]
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
      def ruby_19? ; RUBY_VERSION >= '1.9' ; end
    end
    def connection_mode_dblib? ; self.class.connection_mode_dblib? ; end
    def connection_mode_odbc? ; self.class.connection_mode_odbc? ; end
    def sqlserver_2005? ; self.class.sqlserver_2005? ; end
    def sqlserver_2008? ; self.class.sqlserver_2008? ; end
    def sqlserver_azure? ; self.class.sqlserver_azure? ; end
    def ruby_19? ; self.class.ruby_19? ; end
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
  end
end


