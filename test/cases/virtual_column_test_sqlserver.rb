# frozen_string_literal: true

require "cases/helper_sqlserver"
require "support/schema_dumping_helper"

class VirtualColumnTestSQLServer < ActiveRecord::TestCase
  include SchemaDumpingHelper

  class VirtualColumn < ActiveRecord::Base
  end

  def setup
    @connection = ActiveRecord::Base.lease_connection
    @connection.create_table :virtual_columns, force: true do |t|
      t.string :name
      t.virtual :upper_name, as: "UPPER(name)", stored: true
      t.virtual :lower_name, as: "LOWER(name)", stored: false
      t.virtual :octet_name, as: "LEN(name)"
      t.virtual :mutated_name, as: "REPLACE(name, 'l', 'L')"
      t.integer :column1
    end
    VirtualColumn.create(name: "Rails", column1: 10)
  end

  def teardown
    @connection.drop_table :virtual_columns, if_exists: true
    VirtualColumn.reset_column_information
  end

  def test_virtual_column_with_full_inserts
    partial_inserts_was = VirtualColumn.partial_inserts
    VirtualColumn.partial_inserts = false
    assert_nothing_raised do
      VirtualColumn.create!(name: "Rails")
    end
  ensure
    VirtualColumn.partial_inserts = partial_inserts_was
  end

  def test_stored_column
    column = VirtualColumn.columns_hash["upper_name"]
    assert_predicate column, :virtual?
    assert_predicate column, :virtual_stored?
    assert_equal "RAILS", VirtualColumn.take.upper_name
  end

  def test_explicit_virtual_column
    column = VirtualColumn.columns_hash["lower_name"]
    assert_predicate column, :virtual?
    assert_not_predicate column, :virtual_stored?
    assert_equal "rails", VirtualColumn.take.lower_name
  end

  def test_implicit_virtual_column
    column = VirtualColumn.columns_hash["octet_name"]
    assert_predicate column, :virtual?
    assert_not_predicate column, :virtual_stored?
    assert_equal 5, VirtualColumn.take.octet_name
  end

  def test_virtual_column_with_comma_in_definition
    column = VirtualColumn.columns_hash["mutated_name"]
    assert_predicate column, :virtual?
    assert_not_predicate column, :virtual_stored?
    assert_not_nil column.default_function
    assert_equal "RaiLs", VirtualColumn.take.mutated_name
  end

  def test_change_table_with_stored_generated_column
    @connection.change_table :virtual_columns do |t|
      t.virtual :decr_column1, as: "column1 - 1", stored: true
    end
    VirtualColumn.reset_column_information
    column = VirtualColumn.columns_hash["decr_column1"]
    assert_predicate column, :virtual?
    assert_predicate column, :virtual_stored?
    assert_equal 9, VirtualColumn.take.decr_column1
  end

  def test_change_table_with_explicit_virtual_generated_column
    @connection.change_table :virtual_columns do |t|
      t.virtual :incr_column1, as: "column1 + 1", stored: false
    end
    VirtualColumn.reset_column_information
    column = VirtualColumn.columns_hash["incr_column1"]
    assert_predicate column, :virtual?
    assert_not_predicate column, :virtual_stored?
    assert_equal 11, VirtualColumn.take.incr_column1
  end

  def test_change_table_with_implicit_virtual_generated_column
    @connection.change_table :virtual_columns do |t|
      t.virtual :sqr_column1, as: "power(column1, 2)"
    end
    VirtualColumn.reset_column_information
    column = VirtualColumn.columns_hash["sqr_column1"]
    assert_predicate column, :virtual?
    assert_not_predicate column, :virtual_stored?
    assert_equal 100, VirtualColumn.take.sqr_column1
  end

  def test_schema_dumping
    output = dump_table_schema("virtual_columns")
    assert_match(/t\.virtual\s+"lower_name",\s+as: "\(lower\(\[name\]\)\)", stored: false$/i, output)
    assert_match(/t\.virtual\s+"upper_name",\s+as: "\(upper\(\[name\]\)\)", stored: true$/i, output)
    assert_match(/t\.virtual\s+"octet_name",\s+as: "\(len\(\[name\]\)\)", stored: false$/i, output)
  end

  def test_build_fixture_sql
    fixtures = ActiveRecord::FixtureSet.create_fixtures(FIXTURES_ROOT, :virtual_columns).first
    assert_equal 2, fixtures.size
  end
end
