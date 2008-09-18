require 'cases/helper'
# require File.dirname(__FILE__) + '/../../lib/shoulda'

def uses_shoulda(&blk)
  begin
    require 'rubygems'
    require 'shoulda'
    yield
  rescue Gem::LoadError
    $stderr.puts "Sorry, you need to install shoulda to run these tests: `gem install shoulda`"
  end
end

uses_shoulda do
  class OffsetAndLimitTest < ActiveRecord::TestCase
    def setup
      @connection = ActiveRecord::Base.connection
    end

    context "selecting with limit" do
      setup do
        @select_sql = 'SELECT * FROM schema'
      end

      should "alter SQL to limit number of records returned" do
        options = { :limit => 10 }
        assert_equal('SELECT TOP 10 * FROM schema', @connection.add_limit_offset!(@select_sql, options))
      end

      should "only allow integers for limit" do
        options = { :limit => 'ten' }
        assert_raise(ArgumentError) {@connection.add_limit_offset!(@select_sql, options) }
      end

      should "convert strings which look like integers to integers" do
        options = { :limit => '42' }
        assert_nothing_raised(ArgumentError) {@connection.add_limit_offset!(@select_sql, options)}
      end

      should "not allow sql injection via limit" do
        options = { :limit => '1 * FROM schema; DELETE * FROM table; SELECT TOP 10 *'}
        assert_raise(ArgumentError) { @connection.add_limit_offset!(@select_sql, options) }
      end
    end

    context "selecting with limit and offset" do
      setup do
        # we have to use a real table as we need the counts
        @select_sql = 'SELECT * FROM accounts'
        class Account < ActiveRecord::Base; end

        # create 10 Accounts
        (1..10).each {|i| Account.create!}
      end

      should "have limit if offset is passed" do
        options = { :offset => 1 }
        assert_raise(ArgumentError) { @connection.add_limit_offset!(@select_sql, options) }
      end

      should "only allow integers for offset" do
        options = { :limit => 10, :offset => 'five' }
        assert_raise(ArgumentError) { @connection.add_limit_offset!(@select_sql, options)}
      end

      should "convert strings which look like integers to integers" do
        options = { :limit => 10, :offset => '5' }
        assert_nothing_raised(ArgumentError) {@connection.add_limit_offset!(@select_sql, options)}
      end

      should "alter SQL to limit number of records returned offset by specified amount" do
        options = { :limit => 3, :offset => 5 }
        expected_sql = %&SELECT * FROM (SELECT TOP 3 * FROM (SELECT TOP 8 * FROM accounts) AS tmp1) AS tmp2&
        assert_equal(expected_sql, @connection.add_limit_offset!(@select_sql, options))
      end

      # Not really sure what an offset sql injection might look like
      should "not allow sql injection via offset" do
        options = { :limit => 10, :offset => '1 * FROM schema; DELETE * FROM table; SELECT TOP 10 *'}
        assert_raise(ArgumentError) { @connection.add_limit_offset!(@select_sql, options) }
      end
    end

  end
end