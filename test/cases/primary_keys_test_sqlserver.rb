# frozen_string_literal: true

require "cases/helper_sqlserver"
require "support/schema_dumping_helper"

class PrimaryKeyUuidTypeTest < ActiveRecord::TestCase
  include SchemaDumpingHelper

  self.use_transactional_tests = false

  class Barcode < ActiveRecord::Base
  end

  setup do
    @connection = ActiveRecord::Base.connection
    @connection.create_table(:barcodes, primary_key: "code", id: :uuid, force: true)
  end

  teardown do
    @connection.drop_table(:barcodes, if_exists: true)
  end

  def test_any_type_primary_key
    assert_equal "code", Barcode.primary_key

    column = Barcode.column_for_attribute(Barcode.primary_key)
    assert_not column.null
    assert_equal :uuid, column.type
    assert_not_predicate column, :is_identity?
    assert_predicate column, :is_primary?
  ensure
    Barcode.reset_column_information
  end

  test "schema dump primary key includes default" do
    schema = dump_table_schema "barcodes"
    assert_match %r/create_table "barcodes", primary_key: "code", id: :uuid, default: -> { "newid\(\)" }/, schema
  end
end

class PrimaryKeyIntegerTest < ActiveRecord::TestCase
  include SchemaDumpingHelper

  self.use_transactional_tests = false

  class Barcode < ActiveRecord::Base
  end

  class Widget < ActiveRecord::Base
  end

  setup do
    @connection = ActiveRecord::Base.connection
  end

  teardown do
    @connection.drop_table :barcodes, if_exists: true
    @connection.drop_table :widgets, if_exists: true
  end

  test "integer primary key without default" do
    @connection.create_table(:widgets, id: :integer, force: true)
    column = @connection.columns(:widgets).find { |c| c.name == "id" }
    assert_predicate column, :is_primary?
    assert_predicate column, :is_identity?
    assert_equal :integer, column.type
    assert_not_predicate column, :bigint?

    schema = dump_table_schema "widgets"
    assert_match %r/create_table "widgets", id: :integer, force: :cascade do/, schema
  end

  test "bigint primary key without default" do
    @connection.create_table(:widgets, id: :bigint, force: true)
    column = @connection.columns(:widgets).find { |c| c.name == "id" }
    assert_predicate column, :is_primary?
    assert_predicate column, :is_identity?
    assert_equal :integer, column.type
    assert_predicate column, :bigint?

    schema = dump_table_schema "widgets"
    assert_match %r/create_table "widgets", force: :cascade do/, schema
  end

  test "don't set identity to integer and bigint when there is a default" do
    @connection.create_table(:barcodes, id: :integer, default: nil, force: true)
    @connection.create_table(:widgets, id: :bigint, default: nil, force: true)

    column = @connection.columns(:widgets).find { |c| c.name == "id" }
    assert_predicate column, :is_primary?
    assert_not_predicate column, :is_identity?

    schema = dump_table_schema "widgets"
    assert_match %r/create_table "widgets", id: :bigint, default: nil, force: :cascade do/, schema

    column = @connection.columns(:barcodes).find { |c| c.name == "id" }
    assert_predicate column, :is_primary?
    assert_not_predicate column, :is_identity?

    schema = dump_table_schema "barcodes"
    assert_match %r/create_table "barcodes", id: :integer, default: nil, force: :cascade do/, schema
  end
end
