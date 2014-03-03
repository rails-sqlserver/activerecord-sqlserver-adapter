require 'cases/sqlserver_helper'
require 'models/company'
require 'models/topic'
require 'models/edge'
require 'models/club'
require 'models/organization'

class CalculationsTestSqlserver < ActiveRecord::TestCase
end

class CalculationsTest < ActiveRecord::TestCase

  COERCED_TESTS = [
    :test_should_return_decimal_average_of_integer_field,
    :test_should_sum_expression,
    :test_limit_is_kept,
    :test_limit_with_offset_is_kept,
    :test_offset_is_kept
  ]

  include SqlserverCoercedTest

  fixtures :accounts

  def test_coerced_should_return_decimal_average_of_integer_field
    # Other DBs return 3.5 like this.
    # Account.all.map(&:id).inspect # => [1, 2, 3, 4, 5, 6]
    # (1+2+3+4+5+6)/6.0 # => 3.5
    # But SQL Server does something like this. Bogus!
    # (1+2+3+4+5+6)/6 # => 3
    value = Account.average(:id)
    assert_equal 3, value
  end

  def test_coerced_should_sum_expression
    assert_equal 636, Account.sum("2 * credit_limit")
  end

  def test_coerced_limit_is_kept
    queries = assert_sql { Account.limit(1).count }
    assert_equal 1, queries.length
    assert_match(/TOP \(1\)/, queries.first)
  end

  def test_coerced_limit_with_offset_is_kept
    queries = assert_sql { Account.limit(1).offset(1).count }
    assert_equal 1, queries.length
    assert_match(/TOP \(1\)/, queries.first)
    assert_match(/\[__rn\] > \(1\)/, queries.first)
  end

  def test_coerced_offset_is_kept
    queries = assert_sql { Account.offset(1).count }
    assert_equal 1, queries.length
    assert_match(/\[__rn\] > \(1\)/, queries.first)
  end


end
