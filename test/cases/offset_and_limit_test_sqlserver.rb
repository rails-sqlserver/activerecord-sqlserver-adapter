require 'cases/sqlserver_helper'

class WhenSelectingWithLimitOffsetAndLimitTest < ActiveRecord::TestCase
  def setup
    @connection = ActiveRecord::Base.connection
    @select_sql = 'SELECT * FROM schema'
  end

  def test_should_alter_SQL_to_limit_number_of_records_returned
    options = { :limit => 10 }
    assert_equal('SELECT TOP 10 * FROM schema', @connection.add_limit_offset!(@select_sql, options))
  end

  def test_should_only_allow_integers_for_limit
    options = { :limit => 'ten' }
    assert_raise(ArgumentError) {@connection.add_limit_offset!(@select_sql, options) }
  end

  def test_should_convert_strings_which_look_like_integers_to_integers
    options = { :limit => '42' }
    assert_nothing_raised(ArgumentError) {@connection.add_limit_offset!(@select_sql, options)}
  end

  def test_should_not_allow_sql_injection_via_limit
    options = { :limit => '1 * FROM schema; DELETE * FROM table; SELECT TOP 10 *'}
    assert_raise(ArgumentError) { @connection.add_limit_offset!(@select_sql, options) }
  end
end

class WhenSelectingWithLimitAndOffsetOffsetAndLimitTest < ActiveRecord::TestCase
  class Account < ActiveRecord::Base; end
  def setup
    @connection = ActiveRecord::Base.connection
    # we have to use a real table as we need the counts
    @select_sql = 'SELECT * FROM accounts'
    # create 10 Accounts
    (1..10).each {|i| Account.create!}
  end

  def test_should_have_limit_if_offset_is_passed
    options = { :offset => 1 }
    assert_raise(ArgumentError) { @connection.add_limit_offset!(@select_sql, options) }
  end

  def test_should_only_allow_integers_for_offset
    options = { :limit => 10, :offset => 'five' }
    assert_raise(ArgumentError) { @connection.add_limit_offset!(@select_sql, options)}
  end

  def test_should_convert_strings_which_look_like_integers_to_integers
    options = { :limit => 10, :offset => '5' }
    assert_nothing_raised(ArgumentError) {@connection.add_limit_offset!(@select_sql, options)}
  end

  def test_should_alter_SQL_to_limit_number_of_records_returned_offset_by_specified_amount
    options = { :limit => 3, :offset => 5 }
    expected_sql = %&SELECT * FROM (SELECT TOP 3 * FROM (SELECT TOP 8 * FROM accounts) AS tmp1) AS tmp2&
    assert_equal(expected_sql, @connection.add_limit_offset!(@select_sql, options))
  end

  # Not really sure what an offset sql injection might look like
  def test_should_not_allow_sql_injection_via_offset
    options = { :limit => 10, :offset => '1 * FROM schema; DELETE * FROM table; SELECT TOP 10 *'}
    assert_raise(ArgumentError) { @connection.add_limit_offset!(@select_sql, options) }
  end
end
