require 'cases/helper'
require "cases/aaa_create_tables_test"

# TODO Should this really be in the same test class as the "real" one in rails?
class AAACreateTablesTest < ActiveRecord::TestCase
  def test_load_sqlserver_specific_schema
    eval(File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', 'schema', 'sqlserver_specific_schema.rb'))))
    assert true
  end
end