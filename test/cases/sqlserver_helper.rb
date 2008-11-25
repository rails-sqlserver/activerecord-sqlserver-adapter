require 'rubygems'
require 'shoulda'
require 'mocha'
require 'cases/helper'
require 'models/topic'

SQLSERVER_TEST_ROOT       = File.expand_path(File.join(File.dirname(__FILE__),'..'))
SQLSERVER_ASSETS_ROOT     = SQLSERVER_TEST_ROOT + "/assets"
SQLSERVER_FIXTURES_ROOT   = SQLSERVER_TEST_ROOT + "/fixtures"
SQLSERVER_MIGRATIONS_ROOT = SQLSERVER_TEST_ROOT + "/migrations"
SQLSERVER_SCHEMA_ROOT     = SQLSERVER_TEST_ROOT + "/schema"
ACTIVERECORD_TEST_ROOT    = File.expand_path(SQLSERVER_TEST_ROOT + "/../../../../rails/activerecord/test/")

ActiveRecord::Migration.verbose = false

# Defining our classes in one place as well as soem core tests that need coercing date/time types.

class TableWithRealColumn < ActiveRecord::Base; end
class FkTestHasFk < ActiveRecord::Base ; end
class FkTestHasPk < ActiveRecord::Base ; end
class NumericData < ActiveRecord::Base ; self.table_name = 'numeric_data' ; end
class CustomersView < ActiveRecord::Base ; self.table_name = 'customers_view' ; end
class SqlServerUnicode < ActiveRecord::Base ; end
class SqlServerString < ActiveRecord::Base ; end
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
      undef_method(method) if coerced_tests && coerced_tests.include?(method)
    end
  end
end

# Change the text database type to support ActiveRecord's tests for = on text columns which 
# is not supported in SQL Server text columns, so use varchar(8000) instead.

if ActiveRecord::Base.connection.sqlserver_2000?
  ActiveRecord::ConnectionAdapters::SQLServerAdapter.native_text_database_type = 'varchar(8000)'
end

# Our changes/additions to ActiveRecord test helpers specific for SQL Server.

ActiveRecord::Base.connection.class.class_eval do
  IGNORED_SQL << /SELECT SCOPE_IDENTITY/ << /INFORMATION_SCHEMA.TABLES/ << /INFORMATION_SCHEMA.COLUMNS/
end

ActiveRecord::ConnectionAdapters::SQLServerAdapter.class_eval do
  def raw_select_with_query_record(sql, name = nil)
    $queries_executed ||= []
    $queries_executed << sql unless IGNORED_SQL.any? { |r| sql =~ r }
    raw_select_without_query_record(sql,name)
  end
  alias_method_chain :raw_select, :query_record
end

module ActiveRecord 
  class TestCase < ActiveSupport::TestCase
    class << self
      def sqlserver_2000? ; ActiveRecord::Base.connection.sqlserver_2000? ; end
      def sqlserver_2005? ; ActiveRecord::Base.connection.sqlserver_2005? ; end
    end
    def assert_sql(*patterns_to_match)
      $queries_executed = []
      yield
    ensure
      failed_patterns = []
      patterns_to_match.each do |pattern|
        failed_patterns << pattern unless $queries_executed.any?{ |sql| pattern === sql }
      end
      assert failed_patterns.empty?, "Query pattern(s) #{failed_patterns.map(&:inspect).join(', ')} not found in:\n#{$queries_executed.inspect}"
    end
    def sqlserver_2000? ; self.class.sqlserver_2000? ; end
    def sqlserver_2005? ; self.class.sqlserver_2005? ; end
  end
end


