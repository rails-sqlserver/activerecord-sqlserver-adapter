require 'cases/sqlserver_helper'

class StringDefaults < ActiveRecord::Base; end;

class SpecificSchemaTestSqlserver < ActiveRecord::TestCase

  def test_sqlserver_default_strings_before_save
    default = StringDefaults.new
    assert_equal nil, default.string_with_null_default
    assert_equal 'null', default.string_with_pretend_null_one
    assert_equal '(null)', default.string_with_pretend_null_two
    assert_equal 'NULL', default.string_with_pretend_null_three
    assert_equal '(NULL)', default.string_with_pretend_null_four
  end

  def test_sqlserver_default_strings_after_save
    default = StringDefaults.create
    assert_equal nil, default.string_with_null_default
    assert_equal 'null', default.string_with_pretend_null_one
    assert_equal '(null)', default.string_with_pretend_null_two
    assert_equal 'NULL', default.string_with_pretend_null_three
    assert_equal '(NULL)', default.string_with_pretend_null_four
  end

end
