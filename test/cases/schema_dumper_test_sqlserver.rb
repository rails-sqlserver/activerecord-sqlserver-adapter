require 'cases/sqlserver_helper'

# NOTE: The existing schema_dumper_test doesn't test the limits of <4 limit things
# for adapaters that aren't mysql, sqlite or postgres. We should. It also only tests 
# non-standard id dumping for mysql. We'll do that too.
class SchemaDumperTestSqlserver < ActiveRecord::TestCase
  
  def test_schema_dump_includes_limit_constraint_for_integer_columns
    output = standard_dump(/^(?!integer_limits)/)
    assert_match %r{c_int_1.*:limit => 2}, output
    assert_match %r{c_int_2.*:limit => 2}, output
    assert_match %r{c_int_3.*}, output
    assert_match %r{c_int_4.*}, output
    assert_no_match %r{c_int_3.*:limit}, output
    assert_no_match %r{c_int_4.*:limit}, output
  end
  
  def test_sqlserver_schema_dump_should_honor_nonstandard_primary_keys
    output = standard_dump
    match = output.match(%r{create_table "movies"(.*)do})
    assert_not_nil(match, "nonstandardpk table not found")
    assert_match %r(:primary_key => "movieid"), match[1], "non-standard primary key not preserved"
  end
  
  private
  
  def standard_dump(ignore_tables = [])
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = [*ignore_tables]
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end
  
end
