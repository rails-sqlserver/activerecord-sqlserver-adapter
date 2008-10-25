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

# See cases/helper in rails/activerecord. Tell assert_queries to ignore 
# our SELECT SCOPE_IDENTITY stuff.
ActiveRecord::Base.connection.class.class_eval do
  IGNORED_SQL << /SELECT SCOPE_IDENTITY/
end

