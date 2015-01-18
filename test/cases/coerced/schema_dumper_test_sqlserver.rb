require 'cases/helper_sqlserver'
require 'cases/schema_dumper_test'
require 'stringio'

class SchemaDumperTest < ActiveRecord::TestCase

  COERCED_TESTS = [:test_schema_dump_keeps_large_precision_integer_columns_as_decimal, :test_types_line_up]

  include ARTest::SQLServer::CoercedTest

  def test_coerced_schema_dump_keeps_large_precision_integer_columns_as_decimal
    output = standard_dump
    assert_match %r{t.decimal\s+"atoms_in_universe",\s+precision: 38,\s+scale: 0}, output
  end

   def test_coerced_types_line_up
    column_definition_lines.each do |column_set|
      next if column_set.empty?

      lengths = column_set.map do |column|
        if match = column.match(/t\.(?:integer|decimal|float|datetime|timestamp|time|date|text|binary|string|boolean|uuid)\s+"/)
          match[0].length
        end
      end

      assert_equal 1, lengths.uniq.length
    end
  end

end


