require 'rubygems'
require 'shoulda'
require 'mocha'
require 'cases/helper'

SQLSERVER_TEST_ROOT       = File.expand_path(File.join('..',File.dirname(__FILE__)))
SQLSERVER_ASSETS_ROOT     = SQLSERVER_TEST_ROOT + "/assets"
SQLSERVER_FIXTURES_ROOT   = SQLSERVER_TEST_ROOT + "/fixtures"
SQLSERVER_MIGRATIONS_ROOT = SQLSERVER_TEST_ROOT + "/migrations"
SQLSERVER_SCHEMA_ROOT     = SQLSERVER_TEST_ROOT + "/schema"

ActiveRecord::Migration.verbose = false

class TableWithRealColumn < ActiveRecord::Base; end


ActiveRecord::Base.connection.class.class_eval do
  IGNORED_SQL << /SELECT SCOPE_IDENTITY/ << /INFORMATION_SCHEMA.TABLES/ << /INFORMATION_SCHEMA.COLUMNS/
end

module ActiveRecord 
  class TestCase < ActiveSupport::TestCase
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
  end
end


