require 'cases/helper'
require 'models/default'
require 'models/post'
require 'models/task'

class SqlServerAdapterTest < ActiveRecord::TestCase
  class TableWithRealColumn < ActiveRecord::Base; end

  fixtures :posts, :tasks

  def setup
    @connection = ActiveRecord::Base.connection
  end

  def teardown
    @connection.execute("SET LANGUAGE us_english") rescue nil
  end

  def test_real_column_has_float_type
    assert_equal :float, TableWithRealColumn.columns_hash["real_number"].type
  end

  # SQL Server 2000 has a bug where some unambiguous date formats are not
  # correctly identified if the session language is set to german
  def test_date_insertion_when_language_is_german
    @connection.execute("SET LANGUAGE deutsch")

    assert_nothing_raised do
      Task.create(:starting => Time.utc(2000, 1, 31, 5, 42, 0), :ending => Date.new(2006, 12, 31))
    end
  end

  def test_indexes_with_descending_order
    # Make sure we have an index with descending order
    @connection.execute "CREATE INDEX idx_credit_limit ON accounts (credit_limit DESC)" rescue nil
    assert_equal ["credit_limit"], @connection.indexes('accounts').first.columns
  ensure
    @connection.execute "DROP INDEX accounts.idx_credit_limit"
  end

  def test_execute_without_block_closes_statement
    assert_all_statements_used_are_closed do
      @connection.execute("SELECT 1")
    end
  end

  def test_execute_with_block_closes_statement
    assert_all_statements_used_are_closed do
      @connection.execute("SELECT 1") do |sth|
        assert !sth.finished?, "Statement should still be alive within block"
      end
    end
  end

  def test_insert_with_identity_closes_statement
    assert_all_statements_used_are_closed do
      @connection.insert("INSERT INTO accounts ([id], [firm_id],[credit_limit]) values (999, 1, 50)")
    end
  end

  def test_insert_without_identity_closes_statement
    assert_all_statements_used_are_closed do
      @connection.insert("INSERT INTO accounts ([firm_id],[credit_limit]) values (1, 50)")
    end
  end

  def test_active_closes_statement
    assert_all_statements_used_are_closed do
      @connection.active?
    end
  end

  def assert_all_statements_used_are_closed(&block)
    existing_handles = []
    ObjectSpace.each_object(DBI::StatementHandle) {|handle| existing_handles << handle}
    GC.disable

    yield

    used_handles = []
    ObjectSpace.each_object(DBI::StatementHandle) {|handle| used_handles << handle unless existing_handles.include? handle}

    assert_block "No statements were used within given block" do
      used_handles.size > 0
    end

    ObjectSpace.each_object(DBI::StatementHandle) do |handle|
      assert_block "Statement should have been closed within given block" do
        handle.finished?
      end
    end
  ensure
    GC.enable
  end
end

class TypeToSqlForIntegersTest < ActiveRecord::TestCase

  def setup
    @connection = ActiveRecord::Base.connection
  end

  # TODO - ugh these tests are pretty literal...
  def test_should_create_integers_when_no_limit_supplied
    assert_equal 'integer', @connection.type_to_sql(:integer)
  end

  def test_should_create_integers_when_limit_is_4
    assert_equal 'integer', @connection.type_to_sql(:integer, 4)
  end

  def test_should_create_integers_when_limit_is_3
    assert_equal 'integer', @connection.type_to_sql(:integer, 3)
  end

  def test_should_create_smallints_when_limit_is_less_than_3
    assert_equal 'smallint', @connection.type_to_sql(:integer, 2)
    assert_equal 'smallint', @connection.type_to_sql(:integer, 1)
  end

  def test_should_create_bigints_when_limit_is_greateer_than_4
    assert_equal 'bigint', @connection.type_to_sql(:integer, 5)
    assert_equal 'bigint', @connection.type_to_sql(:integer, 6)
    assert_equal 'bigint', @connection.type_to_sql(:integer, 7)
    assert_equal 'bigint', @connection.type_to_sql(:integer, 8)
  end

end

# NOTE: The existing schema_dumper_test doesn't test the limits of <4 limit things
# for adapaters that aren't mysql, sqlite or postgres.  We should.
class SchemaDumperForSqlServerTest < ActiveRecord::TestCase
  def test_schema_dump_includes_limit_constraint_for_integer_columns
    stream = StringIO.new

    ActiveRecord::SchemaDumper.ignore_tables = [/^(?!integer_limits)/]
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    output = stream.string
    assert_match %r{c_int_1.*:limit => 2}, output
    assert_match %r{c_int_2.*:limit => 2}, output
    assert_match %r{c_int_3.*}, output
    assert_match %r{c_int_4.*}, output
    assert_no_match %r{c_int_3.*:limit}, output
    assert_no_match %r{c_int_4.*:limit}, output
  end
end

class StringDefaultsTest < ActiveRecord::TestCase
  class StringDefaults < ActiveRecord::Base; end;

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
