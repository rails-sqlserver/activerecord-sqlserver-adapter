# frozen_string_literal: true

require "cases/helper_sqlserver"

require "models/event"
class UniquenessValidationTest < ActiveRecord::TestCase
  # So sp_executesql swallows this exception. Run without prepared to see it.
  coerce_tests! :test_validate_uniqueness_with_limit
  def test_validate_uniqueness_with_limit_coerced
    connection.unprepared_statement do
      assert_raise(ActiveRecord::ValueTooLong) do
        Event.create(title: "abcdefgh")
      end
    end
  end

  # So sp_executesql swallows this exception. Run without prepared to see it.
  coerce_tests! :test_validate_uniqueness_with_limit_and_utf8
  def test_validate_uniqueness_with_limit_and_utf8_coerced
    connection.unprepared_statement do
      assert_raise(ActiveRecord::ValueTooLong) do
        Event.create(title: "一二三四五六七八")
      end
    end
  end

  # Same as original coerced test except that it handles default SQL Server case-insensitive collation.
  coerce_tests! :test_validate_uniqueness_by_default_database_collation
  def test_validate_uniqueness_by_default_database_collation_coerced
    Topic.validates_uniqueness_of(:author_email_address)

    topic1 = Topic.new(author_email_address: "david@loudthinking.com")
    topic2 = Topic.new(author_email_address: "David@loudthinking.com")

    assert_equal 1, Topic.where(author_email_address: "david@loudthinking.com").count

    assert_not topic1.valid?
    assert_not topic1.save

    # Case insensitive collation (SQL_Latin1_General_CP1_CI_AS) by default.
    # Should not allow "David" if "david" exists.
    assert_not topic2.valid?
    assert_not topic2.save

    assert_equal 1, Topic.where(author_email_address: "david@loudthinking.com").count
    assert_equal 1, Topic.where(author_email_address: "David@loudthinking.com").count
  end
end

class UniquenessValidationWithIndexTest < ActiveRecord::TestCase
  # Need to explicitly set the WHERE clause to truthy.
  coerce_tests! :test_partial_index
  def test_partial_index_coerced
    Topic.validates_uniqueness_of(:title)
    @connection.add_index(:topics, :title, unique: true, where: "approved=1", name: :topics_index)

    t = Topic.create!(title: "abc")
    t.author_name = "John"
    assert_queries(1) do
      t.valid?
    end
  end
end

require "models/event"
module ActiveRecord
  class AdapterTest < ActiveRecord::TestCase
    # Legacy binds are not supported.
    coerce_tests! :test_select_all_insert_update_delete_with_casted_binds

    # As far as I can tell, SQL Server does not support null bytes in strings.
    coerce_tests! :test_update_prepared_statement

    # So sp_executesql swallows this exception. Run without prepared to see it.
    coerce_tests! :test_value_limit_violations_are_translated_to_specific_exception
    def test_value_limit_violations_are_translated_to_specific_exception_coerced
      connection.unprepared_statement do
        error = assert_raises(ActiveRecord::ValueTooLong) do
          Event.create(title: "abcdefgh")
        end
        assert_not_nil error.cause
      end
    end
  end
end

module ActiveRecord
  class AdapterPreventWritesTest < ActiveRecord::TestCase
    # Fix randomly failing test. The loading of the model's schema was affecting the test.
    coerce_tests! :test_errors_when_an_insert_query_is_called_while_preventing_writes
    def test_errors_when_an_insert_query_is_called_while_preventing_writes_coerced
      Subscriber.send(:load_schema!)
      original_test_errors_when_an_insert_query_is_called_while_preventing_writes
    end

    # Fix randomly failing test. The loading of the model's schema was affecting the test.
    coerce_tests! :test_errors_when_an_insert_query_prefixed_by_a_double_dash_comment_containing_read_command_is_called_while_preventing_writes
    def test_errors_when_an_insert_query_prefixed_by_a_double_dash_comment_containing_read_command_is_called_while_preventing_writes_coerced
      Subscriber.send(:load_schema!)
      original_test_errors_when_an_insert_query_prefixed_by_a_double_dash_comment_containing_read_command_is_called_while_preventing_writes
    end

    # Fix randomly failing test. The loading of the model's schema was affecting the test.
    coerce_tests! :test_errors_when_an_insert_query_prefixed_by_a_double_dash_comment_is_called_while_preventing_writes
    def test_errors_when_an_insert_query_prefixed_by_a_double_dash_comment_is_called_while_preventing_writes_coerced
      Subscriber.send(:load_schema!)
      original_test_errors_when_an_insert_query_prefixed_by_a_double_dash_comment_is_called_while_preventing_writes
    end

    # Invalid character encoding causes `ActiveRecord::StatementInvalid` error similar to Postgres.
    coerce_tests! :test_doesnt_error_when_a_select_query_has_encoding_errors
    def test_doesnt_error_when_a_select_query_has_encoding_errors_coerced
      ActiveRecord::Base.while_preventing_writes do
        # TinyTDS fail on encoding errors.
        # But at least we can assert it fails in the client and not before when trying to match the query.
        assert_raises ActiveRecord::StatementInvalid do
          @connection.select_all("SELECT '\xC8'")
        end
      end
    end
  end
end

module ActiveRecord
  class AdapterTestWithoutTransaction < ActiveRecord::TestCase
    # SQL Server does not allow truncation of tables that are referenced by foreign key
    # constraints. So manually remove/add foreign keys in test.
    coerce_tests! :test_truncate_tables
    def test_truncate_tables_coerced
      # Remove foreign key constraint to allow truncation.
      @connection.remove_foreign_key :authors, :author_addresses

      assert_operator Post.count, :>, 0
      assert_operator Author.count, :>, 0
      assert_operator AuthorAddress.count, :>, 0

      @connection.truncate_tables("author_addresses", "authors", "posts")

      assert_equal 0, Post.count
      assert_equal 0, Author.count
      assert_equal 0, AuthorAddress.count
    ensure
      reset_fixtures("posts", "authors", "author_addresses")

      # Restore foreign key constraint.
      @connection.add_foreign_key :authors, :author_addresses
    end

    # SQL Server does not allow truncation of tables that are referenced by foreign key
    # constraints. So manually remove/add foreign keys in test.
    coerce_tests! :test_truncate_tables_with_query_cache
    def test_truncate_tables_with_query_cache
      # Remove foreign key constraint to allow truncation.
      @connection.remove_foreign_key :authors, :author_addresses

      @connection.enable_query_cache!

      assert_operator Post.count, :>, 0
      assert_operator Author.count, :>, 0
      assert_operator AuthorAddress.count, :>, 0

      @connection.truncate_tables("author_addresses", "authors", "posts")

      assert_equal 0, Post.count
      assert_equal 0, Author.count
      assert_equal 0, AuthorAddress.count
    ensure
      reset_fixtures("posts", "authors", "author_addresses")
      @connection.disable_query_cache!

      # Restore foreign key constraint.
      @connection.add_foreign_key :authors, :author_addresses
    end
  end
end

require "models/topic"
class AttributeMethodsTest < ActiveRecord::TestCase
  # Use IFF for boolean statement in SELECT
  coerce_tests! %r{typecast attribute from select to false}
  def test_typecast_attribute_from_select_to_false_coerced
    Topic.create(:title => "Budget")
    topic = Topic.all.merge!(:select => "topics.*, IIF (1 = 2, 1, 0) as is_test").first
    assert_not_predicate topic, :is_test?
  end

  # Use IFF for boolean statement in SELECT
  coerce_tests! %r{typecast attribute from select to true}
  def test_typecast_attribute_from_select_to_true_coerced
    Topic.create(:title => "Budget")
    topic = Topic.all.merge!(:select => "topics.*, IIF (1 = 1, 1, 0) as is_test").first
    assert_predicate topic, :is_test?
  end
end

class BasicsTest < ActiveRecord::TestCase
  # Use square brackets as SQL Server escaped character
  coerce_tests! :test_column_names_are_escaped
  def test_column_names_are_escaped_coerced
    conn = ActiveRecord::Base.connection
    assert_equal "[t]]]", conn.quote_column_name("t]")
  end

  # Just like PostgreSQLAdapter does.
  coerce_tests! :test_respect_internal_encoding

  # Caused in Rails v4.2.5 by adding `firm_id` column in this http://git.io/vBfMs
  # commit. Trust Rails has this covered.
  coerce_tests! :test_find_keeps_multiple_group_values

  def test_update_date_time_attributes
    Time.use_zone("Eastern Time (US & Canada)") do
      topic = Topic.find(1)
      time = Time.zone.parse("2017-07-17 10:56")
      topic.update!(written_on: time)
      assert_equal(time, topic.written_on)
    end
  end

  def test_update_date_time_attributes_with_default_timezone_local
    with_env_tz "America/New_York" do
      with_timezone_config default: :local do
        Time.use_zone("Eastern Time (US & Canada)") do
          topic = Topic.find(1)
          time = Time.zone.parse("2017-07-17 10:56")
          topic.update!(written_on: time)
          assert_equal(time, topic.written_on)
        end
      end
    end
  end

  # SQL Server does not have query for release_savepoint
  coerce_tests! %r{an empty transaction does not raise if preventing writes}
  test "an empty transaction does not raise if preventing writes coerced" do
    ActiveRecord::Base.while_preventing_writes do
      assert_queries(1, ignore_none: true) do
        Bird.transaction do
          ActiveRecord::Base.connection.materialize_transactions
        end
      end
    end
  end
end

class BelongsToAssociationsTest < ActiveRecord::TestCase
  # Since @client.firm is a single first/top, and we use FETCH the order clause is used.
  coerce_tests! :test_belongs_to_does_not_use_order_by

  # Square brackets around column name
  coerce_tests! :test_belongs_to_with_primary_key_joins_on_correct_column
  def test_belongs_to_with_primary_key_joins_on_correct_column_coerced
    sql = Client.joins(:firm_with_primary_key).to_sql
    assert_no_match(/\[firm_with_primary_keys_companies\]\.\[id\]/, sql)
    assert_match(/\[firm_with_primary_keys_companies\]\.\[name\]/, sql)
  end

  # Asserted SQL to get one row different from original test.
  coerce_tests! :test_belongs_to
  def test_belongs_to_coerced
    client = Client.find(3)
    first_firm = companies(:first_firm)
    assert_sql(/FETCH NEXT @(\d) ROWS ONLY(.)*@\1 = 1/) do
      assert_equal first_firm, client.firm
      assert_equal first_firm.name, client.firm.name
    end
  end
end

module ActiveRecord
  class BindParameterTest < ActiveRecord::TestCase
    # Same as original coerced test except log is found using `EXEC sp_executesql` wrapper.
    coerce_tests! :test_binds_are_logged
    def test_binds_are_logged_coerced
      sub   = Arel::Nodes::BindParam.new(1)
      binds = [Relation::QueryAttribute.new("id", 1, Type::Value.new)]
      sql   = "select * from topics where id = #{sub.to_sql}"

      @connection.exec_query(sql, "SQL", binds)

      logged_sql = "EXEC sp_executesql N'#{sql}', N'#{sub.to_sql} int', #{sub.to_sql} = 1"
      message = @subscriber.calls.find { |args| args[4][:sql] == logged_sql }

      assert_equal binds, message[4][:binds]
    end

    # SQL Server adapter does not use a statement cache as query plans are already reused using `EXEC sp_executesql`.
    coerce_tests! :test_statement_cache
    coerce_tests! :test_statement_cache_with_query_cache
    coerce_tests! :test_statement_cache_with_find
    coerce_tests! :test_statement_cache_with_find_by
    coerce_tests! :test_statement_cache_with_in_clause
    coerce_tests! :test_statement_cache_with_sql_string_literal

    # Same as original coerced test except prepared statements include `EXEC sp_executesql` wrapper.
    coerce_tests! :test_bind_params_to_sql_with_prepared_statements, :test_bind_params_to_sql_with_unprepared_statements
    def test_bind_params_to_sql_with_prepared_statements_coerced
      assert_bind_params_to_sql_coerced(prepared: true)
    end

    def test_bind_params_to_sql_with_unprepared_statements_coerced
      @connection.unprepared_statement do
        assert_bind_params_to_sql_coerced(prepared: false)
      end
    end

    private

    def assert_bind_params_to_sql_coerced(prepared:)
      table = Author.quoted_table_name
      pk = "#{table}.#{Author.quoted_primary_key}"

      # prepared_statements: true
      #
      #   EXEC sp_executesql N'SELECT [authors].* FROM [authors] WHERE [authors].[id] IN (@0, @1, @2) OR [authors].[id] IS NULL)', N'@0 bigint, @1 bigint, @2 bigint', @0 = 1, @1 = 2, @2 = 3
      #
      # prepared_statements: false
      #
      #   SELECT [authors].* FROM [authors] WHERE ([authors].[id] IN (1, 2, 3) OR [authors].[id] IS NULL)
      #
      sql_unprepared = "SELECT #{table}.* FROM #{table} WHERE (#{pk} IN (#{bind_params(1..3)}) OR #{pk} IS NULL)"
      sql_prepared = "EXEC sp_executesql N'SELECT #{table}.* FROM #{table} WHERE (#{pk} IN (#{bind_params(1..3)}) OR #{pk} IS NULL)', N'@0 bigint, @1 bigint, @2 bigint', @0 = 1, @1 = 2, @2 = 3"

      authors = Author.where(id: [1, 2, 3, nil])
      assert_equal sql_unprepared, @connection.to_sql(authors.arel)
      assert_sql(prepared ? sql_prepared : sql_unprepared) { assert_equal 3, authors.length }

      # prepared_statements: true
      #
      #   EXEC sp_executesql N'SELECT [authors].* FROM [authors] WHERE [authors].[id] IN (@0, @1, @2)', N'@0 bigint, @1 bigint, @2 bigint', @0 = 1, @1 = 2, @2 = 3
      #
      # prepared_statements: false
      #
      #   SELECT [authors].* FROM [authors] WHERE [authors].[id] IN (1, 2, 3)
      #
      sql_unprepared = "SELECT #{table}.* FROM #{table} WHERE #{pk} IN (#{bind_params(1..3)})"
      sql_prepared = "EXEC sp_executesql N'SELECT #{table}.* FROM #{table} WHERE #{pk} IN (#{bind_params(1..3)})', N'@0 bigint, @1 bigint, @2 bigint', @0 = 1, @1 = 2, @2 = 3"

      authors = Author.where(id: [1, 2, 3, 9223372036854775808])
      assert_equal sql_unprepared, @connection.to_sql(authors.arel)
      assert_sql(prepared ? sql_prepared : sql_unprepared) { assert_equal 3, authors.length }
    end
  end
end

module ActiveRecord
  class InstrumentationTest < ActiveRecord::TestCase
    # Fix randomly failing test. The loading of the model's schema was affecting the test.
    coerce_tests! :test_payload_name_on_load
    def test_payload_name_on_load_coerced
      Book.send(:load_schema!)
      original_test_payload_name_on_load
    end
  end
end

class CalculationsTest < ActiveRecord::TestCase
  # Fix randomly failing test. The loading of the model's schema was affecting the test.
  coerce_tests! :test_offset_is_kept
  def test_offset_is_kept_coerced
    Account.send(:load_schema!)
    original_test_offset_is_kept
  end

  # The SQL Server `AVG()` function for a list of integers returns an integer (not a decimal).
  coerce_tests! :test_should_return_decimal_average_of_integer_field
  def test_should_return_decimal_average_of_integer_field_coerced
    value = Account.average(:id)
    assert_equal 3, value
  end

  # In SQL Server the `AVG()` function for a list of integers returns an integer so need to cast values as decimals before averaging.
  # Match SQL Server limit implementation.
  coerce_tests! :test_select_avg_with_group_by_as_virtual_attribute_with_sql
  def test_select_avg_with_group_by_as_virtual_attribute_with_sql_coerced
    rails_core = companies(:rails_core)

    sql = <<~SQL
      SELECT firm_id, AVG(CAST(credit_limit AS DECIMAL)) AS avg_credit_limit
      FROM accounts
      WHERE firm_id = ?
      GROUP BY firm_id
      ORDER BY firm_id
      OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
    SQL

    account = Account.find_by_sql([sql, rails_core]).first

    # id was not selected, so it should be nil
    # (cannot select id because it wasn't used in the GROUP BY clause)
    assert_nil account.id

    # firm_id was explicitly selected, so it should be present
    assert_equal(rails_core, account.firm)

    # avg_credit_limit should be present as a virtual attribute
    assert_equal(52.5, account.avg_credit_limit)
  end

  # In SQL Server the `AVG()` function for a list of integers returns an integer so need to cast values as decimals before averaging.
  # Order column must be in the GROUP clause.
  coerce_tests! :test_select_avg_with_group_by_as_virtual_attribute_with_ar
  def test_select_avg_with_group_by_as_virtual_attribute_with_ar_coerced
    rails_core = companies(:rails_core)

    account = Account
                .select(:firm_id, "AVG(CAST(credit_limit AS DECIMAL)) AS avg_credit_limit")
                .where(firm: rails_core)
                .group(:firm_id)
                .order(:firm_id)
                .take!

    # id was not selected, so it should be nil
    # (cannot select id because it wasn't used in the GROUP BY clause)
    assert_nil account.id

    # firm_id was explicitly selected, so it should be present
    assert_equal(rails_core, account.firm)

    # avg_credit_limit should be present as a virtual attribute
    assert_equal(52.5, account.avg_credit_limit)
  end

  # In SQL Server the `AVG()` function for a list of integers returns an integer so need to cast values as decimals before averaging.
  # SELECT columns must be in the GROUP clause.
  # Match SQL Server limit implementation.
  coerce_tests! :test_select_avg_with_joins_and_group_by_as_virtual_attribute_with_sql
  def test_select_avg_with_joins_and_group_by_as_virtual_attribute_with_sql_coerced
    rails_core = companies(:rails_core)

    sql = <<~SQL
      SELECT companies.*, AVG(CAST(accounts.credit_limit AS DECIMAL)) AS avg_credit_limit
      FROM companies
      INNER JOIN accounts ON companies.id = accounts.firm_id
      WHERE companies.id = ?
      GROUP BY companies.id, companies.type, companies.firm_id, companies.firm_name, companies.name, companies.client_of, companies.rating, companies.account_id, companies.description, companies.status
      ORDER BY companies.id
      OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
    SQL

    firm = DependentFirm.find_by_sql([sql, rails_core]).first

    # all the DependentFirm attributes should be present
    assert_equal rails_core, firm
    assert_equal rails_core.name, firm.name

    # avg_credit_limit should be present as a virtual attribute
    assert_equal(52.5, firm.avg_credit_limit)
  end


  # In SQL Server the `AVG()` function for a list of integers returns an integer so need to cast values as decimals before averaging.
  # SELECT columns must be in the GROUP clause.
  coerce_tests! :test_select_avg_with_joins_and_group_by_as_virtual_attribute_with_ar
  def test_select_avg_with_joins_and_group_by_as_virtual_attribute_with_ar_coerced
    rails_core = companies(:rails_core)

    firm = DependentFirm
             .select("companies.*", "AVG(CAST(accounts.credit_limit AS DECIMAL)) AS avg_credit_limit")
             .where(id: rails_core)
             .joins(:account)
             .group(:id, :type, :firm_id, :firm_name, :name, :client_of, :rating, :account_id, :description, :status)
             .take!

    # all the DependentFirm attributes should be present
    assert_equal rails_core, firm
    assert_equal rails_core.name, firm.name

    # avg_credit_limit should be present as a virtual attribute
    assert_equal(52.5, firm.avg_credit_limit)
  end

  # Match SQL Server limit implementation
  coerce_tests! :test_limit_is_kept
  def test_limit_is_kept_coerced
    queries = capture_sql_ss { Account.limit(1).count }
    assert_equal 1, queries.length
    assert_match(/ORDER BY \[accounts\]\.\[id\] ASC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY.*@0 = 1/, queries.first)
  end

  # Match SQL Server limit implementation
  coerce_tests! :test_limit_with_offset_is_kept
  def test_limit_with_offset_is_kept_coerced
    queries = capture_sql_ss { Account.limit(1).offset(1).count }
    assert_equal 1, queries.length
    assert_match(/ORDER BY \[accounts\]\.\[id\] ASC OFFSET @0 ROWS FETCH NEXT @1 ROWS ONLY.*@0 = 1, @1 = 1/, queries.first)
  end

  # SQL Server needs an alias for the calculated column
  coerce_tests! :test_distinct_count_all_with_custom_select_and_order
  def test_distinct_count_all_with_custom_select_and_order_coerced
    accounts = Account.distinct.select("credit_limit % 10 AS the_limit").order(Arel.sql("credit_limit % 10"))
    assert_queries(1) { assert_equal 3, accounts.count(:all) }
    assert_queries(1) { assert_equal 3, accounts.load.size }
  end

  # Leave it up to users to format selects/functions so HAVING works correctly.
  coerce_tests! :test_having_with_strong_parameters

  # SELECT columns must be in the GROUP clause. Since since `ids` only selects the primary key you cannot perform this query in SQL Server.
  coerce_tests! :test_ids_with_includes_and_non_primary_key_order
end

module ActiveRecord
  class Migration
    class ChangeSchemaTest < ActiveRecord::TestCase
      # Integer.default is a number and not a string
      coerce_tests! :test_create_table_with_defaults
      def test_create_table_with_defaults_coerce
        connection.create_table :testings do |t|
          t.column :one, :string, default: "hello"
          t.column :two, :boolean, default: true
          t.column :three, :boolean, default: false
          t.column :four, :integer, default: 1
          t.column :five, :text, default: "hello"
        end

        columns = connection.columns(:testings)
        one = columns.detect { |c| c.name == "one" }
        two = columns.detect { |c| c.name == "two" }
        three = columns.detect { |c| c.name == "three" }
        four = columns.detect { |c| c.name == "four" }
        five = columns.detect { |c| c.name == "five" }

        assert_equal "hello", one.default
        assert_equal true, connection.lookup_cast_type_from_column(two).deserialize(two.default)
        assert_equal false, connection.lookup_cast_type_from_column(three).deserialize(three.default)
        assert_equal 1, four.default
        assert_equal "hello", five.default
      end

      # Use precision 6 by default for datetime/timestamp columns. SQL Server uses `datetime2` for date-times with precision.
      coerce_tests! :test_add_column_with_postgresql_datetime_type
      def test_add_column_with_postgresql_datetime_type_coerced
        connection.create_table :testings do |t|
          t.column :foo, :datetime
        end

        column = connection.columns(:testings).find { |c| c.name == "foo" }

        assert_equal :datetime, column.type
        assert_equal "datetime2(6)", column.sql_type
      end

      # Use precision 6 by default for datetime/timestamp columns. SQL Server uses `datetime2` for date-times with precision.
      coerce_tests! :test_change_column_with_timestamp_type
      def test_change_column_with_timestamp_type_coerced
        connection.create_table :testings do |t|
          t.column :foo, :datetime, null: false
        end

        connection.change_column :testings, :foo, :timestamp

        column = connection.columns(:testings).find { |c| c.name == "foo" }

        assert_equal :datetime, column.type
        assert_equal "datetime2(6)", column.sql_type
      end

      # Use precision 6 by default for datetime/timestamp columns. SQL Server uses `datetime2` for date-times with precision.
      coerce_tests! :test_add_column_with_timestamp_type
      def test_add_column_with_timestamp_type_coerced
        connection.create_table :testings do |t|
          t.column :foo, :timestamp
        end

        column = connection.columns(:testings).find { |c| c.name == "foo" }

        assert_equal :datetime, column.type
        assert_equal "datetime2(6)", column.sql_type
      end
    end
  end
end

module ActiveRecord
  class Migration
    class ColumnAttributesTest < ActiveRecord::TestCase
      # We have a default 4000 varying character limit.
      coerce_tests! :test_add_column_without_limit
      def test_add_column_without_limit_coerced
        add_column :test_models, :description, :string, limit: nil
        TestModel.reset_column_information
        _(TestModel.columns_hash["description"].limit).must_equal 4000
      end
    end
  end
end

module ActiveRecord
  class Migration
    class ColumnsTest < ActiveRecord::TestCase
      # Our defaults are real 70000 integers vs '70000' strings.
      coerce_tests! :test_rename_column_preserves_default_value_not_null
      def test_rename_column_preserves_default_value_not_null_coerced
        add_column "test_models", "salary", :integer, :default => 70000
        default_before = connection.columns("test_models").find { |c| c.name == "salary" }.default
        assert_equal 70000, default_before
        rename_column "test_models", "salary", "annual_salary"
        TestModel.reset_column_information
        assert TestModel.column_names.include?("annual_salary")
        default_after = connection.columns("test_models").find { |c| c.name == "annual_salary" }.default
        assert_equal 70000, default_after
      end

      # Dropping the column removes the single index.
      coerce_tests! :test_remove_column_with_multi_column_index
      def test_remove_column_with_multi_column_index_coerced
        add_column "test_models", :hat_size, :integer
        add_column "test_models", :hat_style, :string, :limit => 100
        add_index "test_models", ["hat_style", "hat_size"], :unique => true
        assert_equal 1, connection.indexes("test_models").size
        remove_column("test_models", "hat_size")
        assert_equal [], connection.indexes("test_models").map(&:name)
      end

      # Choose `StatementInvalid` vs `ActiveRecordError`.
      coerce_tests! :test_rename_nonexistent_column
      def test_rename_nonexistent_column_coerced
        exception = ActiveRecord::StatementInvalid
        assert_raise(exception) do
          rename_column "test_models", "nonexistent", "should_fail"
        end
      end
    end
  end
end

class MigrationTest < ActiveRecord::TestCase
  # For some reason our tests set Rails.@_env which breaks test env switching.
  coerce_tests! :test_internal_metadata_stores_environment_when_other_data_exists
  coerce_tests! :test_internal_metadata_stores_environment

  # Same as original but using binary type instead of blob
  coerce_tests! :test_add_column_with_casted_type_if_not_exists_set_to_true
  def test_add_column_with_casted_type_if_not_exists_set_to_true_coerced
    migration_a = Class.new(ActiveRecord::Migration::Current) {
      def version; 100 end
      def migrate(x)
        add_column "people", "last_name", :binary
      end
    }.new

    migration_b = Class.new(ActiveRecord::Migration::Current) {
      def version; 101 end
      def migrate(x)
        add_column "people", "last_name", :binary, if_not_exists: true
      end
    }.new

    ActiveRecord::Migrator.new(:up, [migration_a], @schema_migration, @internal_metadata, 100).migrate
    assert_column Person, :last_name, "migration_a should have created the last_name column on people"

    assert_nothing_raised do
      ActiveRecord::Migrator.new(:up, [migration_b], @schema_migration, @internal_metadata, 101).migrate
    end
  ensure
    Person.reset_column_information
    if Person.column_names.include?("last_name")
      Person.connection.remove_column("people", "last_name")
    end
  end
end

module ActiveRecord
  class Migration
    class CompatibilityTest < ActiveRecord::TestCase
      # Error message depends on the database adapter.
      coerce_tests! :test_create_table_on_7_0
      def test_create_table_on_7_0_coerced
        long_table_name = "a" * (connection.table_name_length + 1)
        migration = Class.new(ActiveRecord::Migration[7.0]) {
          @@long_table_name = long_table_name
          def version; 100 end
          def migrate(x)
            create_table @@long_table_name
          end
        }.new

        error = assert_raises(StandardError) do
          ActiveRecord::Migrator.new(:up, [migration], @schema_migration, @internal_metadata).migrate
        end
        assert_match(/The identifier that starts with '#{long_table_name[0...-1]}' is too long/i, error.message)
      ensure
        connection.drop_table(long_table_name) rescue nil
      end

      # SQL Server truncates long table names when renaming (https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-rename-transact-sql?view=sql-server-ver16).
      coerce_tests! :test_rename_table_on_7_0
      def test_rename_table_on_7_0_coerced
        long_table_name = "a" * (connection.table_name_length + 1)
        connection.create_table(:more_testings)

        migration = Class.new(ActiveRecord::Migration[7.0]) {
          @@long_table_name = long_table_name
          def version; 100 end
          def migrate(x)
            rename_table :more_testings, @@long_table_name
          end
        }.new

        ActiveRecord::Migrator.new(:up, [migration], @schema_migration, @internal_metadata).migrate
        assert connection.table_exists?(long_table_name[0...-1])
        assert_not connection.table_exists?(:more_testings)
        assert connection.table_exists?(long_table_name[0...-1])
      ensure
        connection.drop_table(:more_testings) rescue nil
        connection.drop_table(long_table_name[0...-1]) rescue nil
      end

      # SQL Server has a different maximum index name length.
      coerce_tests! :test_add_index_errors_on_too_long_name_7_0
      def test_add_index_errors_on_too_long_name_7_0_coerced
        long_index_name = 'a' * (connection.index_name_length + 1)

        migration = Class.new(ActiveRecord::Migration[7.0]) {
          @@long_index_name = long_index_name
          def migrate(x)
            add_column :testings, :very_long_column_name_to_test_with, :string
            add_index :testings, [:foo, :bar, :very_long_column_name_to_test_with], name: @@long_index_name
          end
        }.new

        error = assert_raises(StandardError) do
          ActiveRecord::Migrator.new(:up, [migration], @schema_migration, @internal_metadata).migrate
        end
        assert_match(/Index name \'#{long_index_name}\' on table \'testings\' is too long/i, error.message)
      end

      # SQL Server has a different maximum index name length.
      coerce_tests! :test_create_table_add_index_errors_on_too_long_name_7_0
      def test_create_table_add_index_errors_on_too_long_name_7_0_coerced
        long_index_name = 'a' * (connection.index_name_length + 1)

        migration = Class.new(ActiveRecord::Migration[7.0]) {
          @@long_index_name = long_index_name
          def migrate(x)
            create_table :more_testings do |t|
              t.integer :foo
              t.integer :bar
              t.integer :very_long_column_name_to_test_with
              t.index [:foo, :bar, :very_long_column_name_to_test_with], name: @@long_index_name
            end
          end
        }.new

        error = assert_raises(StandardError) do
          ActiveRecord::Migrator.new(:up, [migration], @schema_migration, @internal_metadata).migrate
        end
        assert_match(/Index name \'#{long_index_name}\' on table \'more_testings\' is too long/i, error.message)
      ensure
        connection.drop_table :more_testings rescue nil
      end
    end
  end
end

class CoreTest < ActiveRecord::TestCase
  # I think fixtures are using the wrong time zone and the `:first`
  # `topics`.`bonus_time` attribute of 2005-01-30t15:28:00.00+01:00 is
  # getting local EST time for me and set to "09:28:00.0000000".
  coerce_tests! :test_pretty_print_persisted
end

module ActiveRecord
  module ConnectionAdapters
    # Just like PostgreSQLAdapter does.
    TypeLookupTest.coerce_all_tests! if defined?(TypeLookupTest)

    # All sorts of errors due to how we test. Even setting ENV['RAILS_ENV'] to
    # a value of 'default_env' will still show tests failing. Just ignoring all
    # of them since we have no monkey in this circus.
    MergeAndResolveDefaultUrlConfigTest.coerce_all_tests! if defined?(MergeAndResolveDefaultUrlConfigTest)
    ConnectionHandlerTest.coerce_all_tests! if defined?(ConnectionHandlerTest)
  end
end

module ActiveRecord
  # The original module is hardcoded for PostgreSQL/SQLite/MySQL tests.
  module DatabaseTasksSetupper
    undef_method :setup
    def setup
      @sqlserver_tasks =
        Class.new do
          def create; end

          def drop; end

          def purge; end

          def charset; end

          def collation; end

          def structure_dump(*); end

          def structure_load(*); end
        end.new

      $stdout, @original_stdout = StringIO.new, $stdout
      $stderr, @original_stderr = StringIO.new, $stderr
    end

    undef_method :with_stubbed_new
    def with_stubbed_new
      ActiveRecord::Tasks::SQLServerDatabaseTasks.stub(:new, @sqlserver_tasks) do
        yield
      end
    end
  end

  class DatabaseTasksCreateTest < ActiveRecord::TestCase
    # Coerce PostgreSQL/SQLite/MySQL tests.
    coerce_all_tests!

    def test_sqlserver_create
      with_stubbed_new do
        assert_called(eval("@sqlserver_tasks"), :create) do
          ActiveRecord::Tasks::DatabaseTasks.create "adapter" => :sqlserver
        end
      end
    end
  end

  class DatabaseTasksDropTest < ActiveRecord::TestCase
    # Coerce PostgreSQL/SQLite/MySQL tests.
    coerce_all_tests!

    def test_sqlserver_drop
      with_stubbed_new do
        assert_called(eval("@sqlserver_tasks"), :drop) do
          ActiveRecord::Tasks::DatabaseTasks.drop "adapter" => :sqlserver
        end
      end
    end
  end

  class DatabaseTasksPurgeTest < ActiveRecord::TestCase
    # Coerce PostgreSQL/SQLite/MySQL tests.
    coerce_all_tests!

    def test_sqlserver_purge
      with_stubbed_new do
        assert_called(eval("@sqlserver_tasks"), :purge) do
          ActiveRecord::Tasks::DatabaseTasks.purge "adapter" => :sqlserver
        end
      end
    end
  end

  class DatabaseTasksCharsetTest < ActiveRecord::TestCase
    # Coerce PostgreSQL/SQLite/MySQL tests.
    coerce_all_tests!

    def test_sqlserver_charset
      with_stubbed_new do
        assert_called(eval("@sqlserver_tasks"), :charset) do
          ActiveRecord::Tasks::DatabaseTasks.charset "adapter" => :sqlserver
        end
      end
    end
  end

  class DatabaseTasksCollationTest < ActiveRecord::TestCase
    # Coerce PostgreSQL/SQLite/MySQL tests.
    coerce_all_tests!

    def test_sqlserver_collation
      with_stubbed_new do
        assert_called(eval("@sqlserver_tasks"), :collation) do
          ActiveRecord::Tasks::DatabaseTasks.collation "adapter" => :sqlserver
        end
      end
    end
  end

  class DatabaseTasksStructureDumpTest < ActiveRecord::TestCase
    # Coerce PostgreSQL/SQLite/MySQL tests.
    coerce_all_tests!

    def test_sqlserver_structure_dump
      with_stubbed_new do
        assert_called_with(
          eval("@sqlserver_tasks"), :structure_dump,
          ["awesome-file.sql", nil]
        ) do
          ActiveRecord::Tasks::DatabaseTasks.structure_dump({ "adapter" => :sqlserver }, "awesome-file.sql")
        end
      end
    end
  end

  class DatabaseTasksStructureLoadTest < ActiveRecord::TestCase
    # Coerce PostgreSQL/SQLite/MySQL tests.
    coerce_all_tests!

    def test_sqlserver_structure_load
      with_stubbed_new do
        assert_called_with(
          eval("@sqlserver_tasks"),
          :structure_load,
          ["awesome-file.sql", nil]
        ) do
          ActiveRecord::Tasks::DatabaseTasks.structure_load({ "adapter" => :sqlserver }, "awesome-file.sql")
        end
      end
    end
  end

  class DatabaseTasksCreateAllTest < ActiveRecord::TestCase
    # We extend `local_database?` so that common VM IPs can be used.
    coerce_tests! :test_ignores_remote_databases, :test_warning_for_remote_databases
  end

  class DatabaseTasksDropAllTest < ActiveRecord::TestCase
    # We extend `local_database?` so that common VM IPs can be used.
    coerce_tests! :test_ignores_remote_databases, :test_warning_for_remote_databases
  end
end

class DefaultScopingTest < ActiveRecord::TestCase
  # We are not doing order duplicate removal anymore.
  coerce_tests! :test_order_in_default_scope_should_not_prevail
end

class EagerAssociationTest < ActiveRecord::TestCase
  # Use LEN() instead of LENGTH() function.
  coerce_tests! :test_count_with_include
  def test_count_with_include_coerced
    assert_equal 3, authors(:david).posts_with_comments.where("LEN(comments.body) > 15").references(:comments).count
  end

  # The raw SQL in the scope uses `limit 1`.
  coerce_tests! %r{including association based on sql condition and no database column}
end

require "models/topic"
require "models/customer"
require "models/non_primary_key"
class FinderTest < ActiveRecord::TestCase
  fixtures :customers, :topics, :authors

  # We have implicit ordering, via FETCH.
  coerce_tests! %r{doesn't have implicit ordering},
                :test_find_doesnt_have_implicit_ordering

  # Assert SQL Server limit implementation
  coerce_tests! :test_take_and_first_and_last_with_integer_should_use_sql_limit
  def test_take_and_first_and_last_with_integer_should_use_sql_limit_coerced
    assert_sql(/OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY.* @0 = 3/) { Topic.take(3).entries }
    assert_sql(/OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY.* @0 = 2/) { Topic.first(2).entries }
    assert_sql(/OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY.* @0 = 5/) { Topic.last(5).entries }
  end

  # This fails only when run in the full test suite task. Just taking it out of the mix.
  coerce_tests! :test_find_with_order_on_included_associations_with_construct_finder_sql_for_association_limiting_and_is_distinct

  # Can not use array condition due to not finding right type and hence fractional second quoting.
  coerce_tests! :test_condition_utc_time_interpolation_with_default_timezone_local
  def test_condition_utc_time_interpolation_with_default_timezone_local_coerced
    with_env_tz "America/New_York" do
      with_timezone_config default: :local do
        topic = Topic.first
        assert_equal topic, Topic.where(written_on: topic.written_on.getutc).first
      end
    end
  end

  # Can not use array condition due to not finding right type and hence fractional second quoting.
  coerce_tests! :test_condition_local_time_interpolation_with_default_timezone_utc
  def test_condition_local_time_interpolation_with_default_timezone_utc_coerced
    with_env_tz "America/New_York" do
      with_timezone_config default: :utc do
        topic = Topic.first
        assert_equal topic, Topic.where(written_on: topic.written_on.getlocal).first
      end
    end
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_include_on_unloaded_relation_with_match
  def test_include_on_unloaded_relation_with_match_coerced
    assert_sql(/1 AS one.*FETCH NEXT @2 ROWS ONLY.*@2 = 1/) do
      assert_equal true, Customer.where(name: "David").include?(customers(:david))
    end
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_include_on_unloaded_relation_without_match
  def test_include_on_unloaded_relation_without_match_coerced
    assert_sql(/1 AS one.*FETCH NEXT @2 ROWS ONLY.*@2 = 1/) do
      assert_equal false, Customer.where(name: "David").include?(customers(:mary))
    end
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_member_on_unloaded_relation_with_match
  def test_member_on_unloaded_relation_with_match_coerced
    assert_sql(/1 AS one.*FETCH NEXT @2 ROWS ONLY.*@2 = 1/) do
      assert_equal true, Customer.where(name: "David").member?(customers(:david))
    end
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_member_on_unloaded_relation_without_match
  def test_member_on_unloaded_relation_without_match_coerced
    assert_sql(/1 AS one.*FETCH NEXT @2 ROWS ONLY.*@2 = 1/) do
      assert_equal false, Customer.where(name: "David").member?(customers(:mary))
    end
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_implicit_order_column_is_configurable
  def test_implicit_order_column_is_configurable_coerced
    old_implicit_order_column = Topic.implicit_order_column
    Topic.implicit_order_column = "title"

    assert_equal topics(:fifth), Topic.first
    assert_equal topics(:third), Topic.last

    c = Topic.connection
    assert_sql(/ORDER BY #{Regexp.escape(c.quote_table_name("topics.title"))} DESC, #{Regexp.escape(c.quote_table_name("topics.id"))} DESC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY.*@0 = 1/i) {
      Topic.last
    }
  ensure
    Topic.implicit_order_column = old_implicit_order_column
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_implicit_order_set_to_primary_key
  def test_implicit_order_set_to_primary_key_coerced
    old_implicit_order_column = Topic.implicit_order_column
    Topic.implicit_order_column = "id"

    c = Topic.connection
    assert_sql(/ORDER BY #{Regexp.escape(c.quote_table_name("topics.id"))} DESC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY.*@0 = 1/i) {
      Topic.last
    }
  ensure
    Topic.implicit_order_column = old_implicit_order_column
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_implicit_order_for_model_without_primary_key
  def test_implicit_order_for_model_without_primary_key_coerced
    old_implicit_order_column = NonPrimaryKey.implicit_order_column
    NonPrimaryKey.implicit_order_column = "created_at"

    c = NonPrimaryKey.connection

    assert_sql(/ORDER BY #{Regexp.escape(c.quote_table_name("non_primary_keys.created_at"))} DESC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY.*@0 = 1/i) {
      NonPrimaryKey.last
    }
  ensure
    NonPrimaryKey.implicit_order_column = old_implicit_order_column
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_member_on_unloaded_relation_with_composite_primary_key
  def test_member_on_unloaded_relation_with_composite_primary_key_coerced
    assert_sql(/1 AS one.* FETCH NEXT @(\d) ROWS ONLY.*@\1 = 1/) do
      book = cpk_books(:cpk_great_author_first_book)
      assert Cpk::Book.where(title: "The first book").member?(book)
    end
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_implicit_order_column_prepends_query_constraints
  def test_implicit_order_column_prepends_query_constraints_coerced
    c = ClothingItem.connection
    ClothingItem.implicit_order_column = "description"
    quoted_type = Regexp.escape(c.quote_table_name("clothing_items.clothing_type"))
    quoted_color = Regexp.escape(c.quote_table_name("clothing_items.color"))
    quoted_descrption = Regexp.escape(c.quote_table_name("clothing_items.description"))

    assert_sql(/ORDER BY #{quoted_descrption} ASC, #{quoted_type} ASC, #{quoted_color} ASC OFFSET 0 ROWS FETCH NEXT @(\d) ROWS ONLY.*@\1 = 1/i) do
      assert_kind_of ClothingItem, ClothingItem.first
    end
  ensure
    ClothingItem.implicit_order_column = nil
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! %r{#last for a model with composite query constraints}
  test "#last for a model with composite query constraints coerced" do
    c = ClothingItem.connection
    quoted_type = Regexp.escape(c.quote_table_name("clothing_items.clothing_type"))
    quoted_color = Regexp.escape(c.quote_table_name("clothing_items.color"))

    assert_sql(/ORDER BY #{quoted_type} DESC, #{quoted_color} DESC OFFSET 0 ROWS FETCH NEXT @(\d) ROWS ONLY.*@\1 = 1/i) do
      assert_kind_of ClothingItem, ClothingItem.last
    end
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! %r{#first for a model with composite query constraints}
  test "#first for a model with composite query constraints coerced" do
    c = ClothingItem.connection
    quoted_type = Regexp.escape(c.quote_table_name("clothing_items.clothing_type"))
    quoted_color = Regexp.escape(c.quote_table_name("clothing_items.color"))

    assert_sql(/ORDER BY #{quoted_type} ASC, #{quoted_color} ASC OFFSET 0 ROWS FETCH NEXT @(\d) ROWS ONLY.*@\1 = 1/i) do
      assert_kind_of ClothingItem, ClothingItem.first
    end
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_implicit_order_column_reorders_query_constraints
  def test_implicit_order_column_reorders_query_constraints_coerced
    c = ClothingItem.connection
    ClothingItem.implicit_order_column = "color"
    quoted_type = Regexp.escape(c.quote_table_name("clothing_items.clothing_type"))
    quoted_color = Regexp.escape(c.quote_table_name("clothing_items.color"))

    assert_sql(/ORDER BY #{quoted_color} ASC, #{quoted_type} ASC OFFSET 0 ROWS FETCH NEXT @(\d) ROWS ONLY.*@\1 = 1/i) do
      assert_kind_of ClothingItem, ClothingItem.first
    end
  ensure
    ClothingItem.implicit_order_column = nil
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_include_on_unloaded_relation_with_composite_primary_key
  def test_include_on_unloaded_relation_with_composite_primary_key_coerced
    assert_sql(/1 AS one.*OFFSET 0 ROWS FETCH NEXT @(\d) ROWS ONLY.*@\1 = 1/) do
      book = cpk_books(:cpk_great_author_first_book)
      assert Cpk::Book.where(title: "The first book").include?(book)
    end
  end

  # Check for `FETCH NEXT x ROWS` rather then `LIMIT`.
  coerce_tests! :test_nth_to_last_with_order_uses_limit
  def test_nth_to_last_with_order_uses_limit_coerced
    c = Topic.connection
    assert_sql(/ORDER BY #{Regexp.escape(c.quote_table_name("topics.id"))} DESC OFFSET @(\d) ROWS FETCH NEXT @(\d) ROWS ONLY.*@\1 = 1.*@\2 = 1/i) do
      Topic.second_to_last
    end

    assert_sql(/ORDER BY #{Regexp.escape(c.quote_table_name("topics.updated_at"))} DESC OFFSET @(\d) ROWS FETCH NEXT @(\d) ROWS ONLY.*@\1 = 1.*@\2 = 1/i) do
      Topic.order(:updated_at).second_to_last
    end
  end

  # SQL Server is unable to use aliased SELECT in the HAVING clause.
  coerce_tests! :test_include_on_unloaded_relation_with_having_referencing_aliased_select
end

module ActiveRecord
  class Migration
    class ForeignKeyTest < ActiveRecord::TestCase
      # SQL Server does not support 'restrict' for 'on_update' or 'on_delete'.
      coerce_tests! :test_add_on_delete_restrict_foreign_key
      def test_add_on_delete_restrict_foreign_key_coerced
        assert_raises ArgumentError do
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", on_delete: :restrict
        end
        assert_raises ArgumentError do
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", on_update: :restrict
        end
      end

      # Error message depends on the database adapter.
      coerce_tests! :test_add_foreign_key_with_if_not_exists_not_set
      def test_add_foreign_key_with_if_not_exists_not_set_coerced
        @connection.add_foreign_key :astronauts, :rockets
        assert_equal 1, @connection.foreign_keys("astronauts").size

        error = assert_raises do
          @connection.add_foreign_key :astronauts, :rockets
        end

        assert_match(/TinyTds::Error: There is already an object named '.*' in the database/, error.message)
      end
    end
  end
end

class HasOneAssociationsTest < ActiveRecord::TestCase
  # We use OFFSET/FETCH vs TOP. So we always have an order.
  coerce_tests! :test_has_one_does_not_use_order_by

  # Asserted SQL to get one row different from original test.
  coerce_tests! :test_has_one
  def test_has_one_coerced
    firm = companies(:first_firm)
    first_account = Account.find(1)
    assert_sql(/FETCH NEXT @(\d) ROWS ONLY(.)*@\1 = 1/) do
      assert_equal first_account, firm.account
      assert_equal first_account.credit_limit, firm.account.credit_limit
    end
  end
end

class HasOneThroughAssociationsTest < ActiveRecord::TestCase
  # Asserted SQL to get one row different from original test.
  coerce_tests! :test_has_one_through_executes_limited_query
  def test_has_one_through_executes_limited_query_coerced
    boring_club = clubs(:boring_club)
    assert_sql(/FETCH NEXT @(\d) ROWS ONLY(.)*@\1 = 1/) do
      assert_equal boring_club, @member.general_club
    end
  end
end

class LeftOuterJoinAssociationTest < ActiveRecord::TestCase
  # Uses || operator in SQL. Just trust core gets value out of this test.
  coerce_tests! :test_does_not_override_select
end

require "models/developer"
require "models/computer"
class NestedRelationScopingTest < ActiveRecord::TestCase
  # Assert SQL Server limit implementation
  coerce_tests! :test_merge_options
  def test_merge_options_coerced
    Developer.where("salary = 80000").scoping do
      Developer.limit(10).scoping do
        devs = Developer.all
        sql = devs.to_sql
        assert_match "(salary = 80000)", sql
        assert_match "FETCH NEXT 10 ROWS ONLY", sql
      end
    end
  end
end

require "models/topic"
class PersistenceTest < ActiveRecord::TestCase
  # Rails test required updating a identity column.
  coerce_tests! :test_update_columns_changing_id

  # Rails test required updating a identity column.
  coerce_tests! :test_update
  def test_update_coerced
    topic = Topic.find(1)
    assert_not_predicate topic, :approved?
    assert_equal "The First Topic", topic.title

    topic.update("approved" => true, "title" => "The First Topic Updated")
    topic.reload
    assert_predicate topic, :approved?
    assert_equal "The First Topic Updated", topic.title

    topic.update(approved: false, title: "The First Topic")
    topic.reload
    assert_not_predicate topic, :approved?
    assert_equal "The First Topic", topic.title
  end
end

require "models/author"
class UpdateAllTest < ActiveRecord::TestCase
  # Rails test required updating a identity column.
  coerce_tests! :test_update_all_doesnt_ignore_order
  def test_update_all_doesnt_ignore_order_coerced
    david, mary = authors(:david), authors(:mary)
    _(david.id).must_equal 1
    _(mary.id).must_equal 2
    _(david.name).wont_equal mary.name
    assert_sql(/UPDATE.*\(SELECT \[authors\].\[id\] FROM \[authors\].*ORDER BY \[authors\].\[id\]/i) do
      Author.where("[id] > 1").order(:id).update_all(name: "Test")
    end
    _(david.reload.name).must_equal "David"
    _(mary.reload.name).must_equal "Test"
  end

  # SELECT columns must be in the GROUP clause.
  coerce_tests! :test_update_all_with_group_by
  def test_update_all_with_group_by_coerced
    minimum_comments_count = 2

    Post.most_commented(minimum_comments_count).update_all(title: "ig")
    posts = Post.select(:id, :title).group(:title).most_commented(minimum_comments_count).all.to_a

    assert_operator posts.length, :>, 0
    assert posts.all? { |post| post.comments.length >= minimum_comments_count }
    assert posts.all? { |post| "ig" == post.title }

    post = Post.select(:id, :title).group(:title).joins(:comments).group("posts.id").having("count(comments.id) < #{minimum_comments_count}").first
    assert_not_equal "ig", post.title
  end
end

class DeleteAllTest < ActiveRecord::TestCase
  # SELECT columns must be in the GROUP clause.
  coerce_tests! :test_delete_all_with_group_by_and_having
  def test_delete_all_with_group_by_and_having_coerced
    minimum_comments_count = 2
    posts_to_be_deleted = Post.select(:id).most_commented(minimum_comments_count).all.to_a
    assert_operator posts_to_be_deleted.length, :>, 0

    assert_difference("Post.count", -posts_to_be_deleted.length) do
      Post.most_commented(minimum_comments_count).delete_all
    end

    posts_to_be_deleted.each do |deleted_post|
      assert_raise(ActiveRecord::RecordNotFound) { deleted_post.reload }
    end
  end
end

require "models/topic"
module ActiveRecord
  class PredicateBuilderTest < ActiveRecord::TestCase
    # Same as original test except string has `N` prefix to indicate unicode string.
    coerce_tests! :test_registering_new_handlers
    def test_registering_new_handlers_coerced
      assert_match %r{#{Regexp.escape(topic_title)} ~ N'rails'}i, Topic.where(title: /rails/).to_sql
    end

    # Same as original test except string has `N` prefix to indicate unicode string.
    coerce_tests! :test_registering_new_handlers_for_association
    def test_registering_new_handlers_for_association_coerced
      assert_match %r{#{Regexp.escape(topic_title)} ~ N'rails'}i, Reply.joins(:topic).where(topics: { title: /rails/ }).to_sql
    end
  end
end

class PrimaryKeysTest < ActiveRecord::TestCase
  # SQL Server does not have query for release_savepoint
  coerce_tests! :test_create_without_primary_key_no_extra_query
  def test_create_without_primary_key_no_extra_query_coerced
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = "dashboards"
    end
    klass.create! # warmup schema cache
    assert_queries(2, ignore_none: true) { klass.create! }
  end
end

require "models/task"
class QueryCacheTest < ActiveRecord::TestCase
  # SQL Server adapter not in list of supported adapters in original test.
  coerce_tests! :test_cache_does_not_wrap_results_in_arrays
  def test_cache_does_not_wrap_results_in_arrays_coerced
    Task.cache do
      assert_equal 2, Task.connection.select_value("SELECT count(*) AS count_all FROM tasks")
    end
  end

  # Same as original test except that we expect one query to be performed to retrieve the table's primary key
  # and we don't call `reload_type_map` because SQL Server adapter doesn't support it.
  # When we generate the SQL for the `find` it includes ordering on the primary key. If we reset the column
  # information then the primary key needs to be retrieved from the database again to generate the SQL causing the
  # original test's `assert_no_queries` assertion to fail. Assert that the query was to get the primary key.
  coerce_tests! :test_query_cached_even_when_types_are_reset
  def test_query_cached_even_when_types_are_reset_coerced
    Task.cache do
      # Warm the cache
      Task.find(1)

      # Clear places where type information is cached
      Task.reset_column_information
      Task.initialize_find_by_cache
      Task.define_attribute_methods

      assert_queries(1, ignore_none: true) do
        Task.find(1)
      end

      assert_includes ActiveRecord::SQLCounter.log_all.first, "TC.CONSTRAINT_TYPE = N''PRIMARY KEY''"
    end
  end
end

require "models/post"
class RelationTest < ActiveRecord::TestCase
  # Use LEN() instead of LENGTH() function.
  coerce_tests! :test_reverse_order_with_function
  def test_reverse_order_with_function_coerced
    topics = Topic.order(Arel.sql("LEN(title)")).reverse_order
    assert_equal topics(:second).title, topics.first.title
  end

  # Use LEN() instead of LENGTH() function.
  coerce_tests! :test_reverse_order_with_function_other_predicates
  def test_reverse_order_with_function_other_predicates_coerced
    topics = Topic.order(Arel.sql("author_name, LEN(title), id")).reverse_order
    assert_equal topics(:second).title, topics.first.title
    topics = Topic.order(Arel.sql("LEN(author_name), id, LEN(title)")).reverse_order
    assert_equal topics(:fifth).title, topics.first.title
  end

  # We have implicit ordering, via FETCH.
  coerce_tests! %r{doesn't have implicit ordering}

  # We have implicit ordering, via FETCH.
  coerce_tests! :test_reorder_with_take
  def test_reorder_with_take_coerced
    sql_log = capture_sql do
      assert Post.order(:title).reorder(nil).take
    end
    assert sql_log.none? { |sql| /order by \[posts\]\.\[title\]/i.match?(sql) }, "ORDER BY title was used in the query: #{sql_log}"
    assert sql_log.all?  { |sql| /order by \[posts\]\.\[id\]/i.match?(sql) }, "default ORDER BY ID was not used in the query: #{sql_log}"
  end

  # We have implicit ordering, via FETCH.
  coerce_tests! :test_reorder_with_first
  def test_reorder_with_first_coerced
    post = nil
    sql_log = capture_sql do
      post = Post.order(:title).reorder(nil).first
    end
    assert_equal posts(:welcome), post
    assert sql_log.none? { |sql| /order by \[posts\]\.\[title\]/i.match?(sql) }, "ORDER BY title was used in the query: #{sql_log}"
    assert sql_log.all?  { |sql| /order by \[posts\]\.\[id\]/i.match?(sql) }, "default ORDER BY ID was not used in the query: #{sql_log}"
  end

  # We are not doing order duplicate removal anymore.
  coerce_tests! :test_order_using_scoping

  # We are not doing order duplicate removal anymore.
  coerce_tests! :test_default_scope_order_with_scope_order

  # Order column must be in the GROUP clause.
  coerce_tests! :test_multiple_where_and_having_clauses
  def test_multiple_where_and_having_clauses_coerced
    post = Post.first
    having_then_where = Post.having(id: post.id).where(title: post.title)
                            .having(id: post.id).where(title: post.title).group(:id).select(:id)

    assert_equal [post], having_then_where
  end

  # Order column must be in the GROUP clause.
  coerce_tests! :test_having_with_binds_for_both_where_and_having
  def test_having_with_binds_for_both_where_and_having
    post = Post.first
    having_then_where = Post.having(id: post.id).where(title: post.title).group(:id).select(:id)
    where_then_having = Post.where(title: post.title).having(id: post.id).group(:id).select(:id)

    assert_equal [post], having_then_where
    assert_equal [post], where_then_having
  end

  # Find any limit via our expression.
  coerce_tests! %r{relations don't load all records in #inspect}
  def test_relations_dont_load_all_records_in_inspect_coerced
    assert_sql(/NEXT @0 ROWS.*@0 = \d+/) do
      Post.all.inspect
    end
  end

  # Find any limit via our expression.
  coerce_tests! %r{relations don't load all records in #pretty_print}
  def test_relations_dont_load_all_records_in_pretty_print_coerced
    assert_sql(/FETCH NEXT @(\d) ROWS ONLY/) do
      PP.pp Post.all, StringIO.new # avoid outputting.
    end
  end

  # Order column must be in the GROUP clause.
  coerce_tests! :test_empty_complex_chained_relations
  def test_empty_complex_chained_relations_coerced
    posts = Post.select("comments_count").where("id is not null").group("author_id", "id").where("legacy_comments_count > 0")

    assert_queries(1) { assert_equal false, posts.empty? }
    assert_not_predicate posts, :loaded?

    no_posts = posts.where(title: "")
    assert_queries(1) { assert_equal true, no_posts.empty? }
    assert_not_predicate no_posts, :loaded?
  end

  # Can't apply offset without ORDER
  coerce_tests! %r{using a custom table affects the wheres}
  test "using a custom table affects the wheres coerced" do
    post = posts(:welcome)

    assert_equal post, custom_post_relation.where!(title: post.title).order(:id).take
  end

  # Can't apply offset without ORDER
  coerce_tests! %r{using a custom table with joins affects the joins}
  test "using a custom table with joins affects the joins coerced" do
    post = posts(:welcome)

    assert_equal post, custom_post_relation.joins(:author).where!(title: post.title).order(:id).take
  end

  # Use LEN() instead of LENGTH() function.
  coerce_tests! :test_reverse_arel_assoc_order_with_function
  def test_reverse_arel_assoc_order_with_function_coerced
    topics = Topic.order(Arel.sql("LEN(title)") => :asc).reverse_order
    assert_equal topics(:second).title, topics.first.title
  end
end

module ActiveRecord
  class RelationTest < ActiveRecord::TestCase
    # Skipping this test. SQL Server doesn't support optimizer hint as comments
    coerce_tests! :test_relation_with_optimizer_hints_filters_sql_comment_delimiters

    coerce_tests! :test_does_not_duplicate_optimizer_hints_on_merge
    def test_does_not_duplicate_optimizer_hints_on_merge_coerced
      escaped_table = Post.connection.quote_table_name("posts")
      expected = "SELECT #{escaped_table}.* FROM #{escaped_table} OPTION (OMGHINT)"
      query = Post.optimizer_hints("OMGHINT").merge(Post.optimizer_hints("OMGHINT")).to_sql
      assert_equal expected, query
    end
  end
end

require "models/post"
class SanitizeTest < ActiveRecord::TestCase
  # Use nvarchar string (N'') in assert
  coerce_tests! :test_sanitize_sql_like_example_use_case
  def test_sanitize_sql_like_example_use_case_coerced
    searchable_post = Class.new(Post) do
      def self.search_as_method(term)
        where("title LIKE ?", sanitize_sql_like(term, "!"))
      end

      scope :search_as_scope, ->(term) {
        where("title LIKE ?", sanitize_sql_like(term, "!"))
      }
    end

    assert_sql(/LIKE N'20!% !_reduction!_!!'/) do
      searchable_post.search_as_method("20% _reduction_!").to_a
    end

    assert_sql(/LIKE N'20!% !_reduction!_!!'/) do
      searchable_post.search_as_scope("20% _reduction_!").to_a
    end
  end

  # Use nvarchar string (N'') in assert
  coerce_tests! :test_named_bind_with_literal_colons
  def test_named_bind_with_literal_colons_coerced
    assert_equal "TO_TIMESTAMP(N'2017/08/02 10:59:00', 'YYYY/MM/DD HH12:MI:SS')", bind("TO_TIMESTAMP(:date, 'YYYY/MM/DD HH12\\:MI\\:SS')", date: "2017/08/02 10:59:00")
    assert_raise(ActiveRecord::PreparedStatementInvalid) { bind "TO_TIMESTAMP(:date, 'YYYY/MM/DD HH12:MI:SS')", date: "2017/08/02 10:59:00" }
  end
end

class SchemaDumperTest < ActiveRecord::TestCase
  # Use nvarchar string (N'') in assert
  coerce_tests! :test_dump_schema_information_outputs_lexically_reverse_ordered_versions_regardless_of_database_order
  def test_dump_schema_information_outputs_lexically_reverse_ordered_versions_regardless_of_database_order_coerced
    versions = %w{ 20100101010101 20100201010101 20100301010101 }
    versions.shuffle.each do |v|
      @schema_migration.create_version(v)
    end

    schema_info = ActiveRecord::Base.connection.dump_schema_information
    expected = <<~STR
    INSERT INTO #{ActiveRecord::Base.connection.quote_table_name("schema_migrations")} (version) VALUES
    (N'20100301010101'),
    (N'20100201010101'),
    (N'20100101010101');
    STR
    assert_equal expected.strip, schema_info
  ensure
    @schema_migration.delete_all_versions
  end

  # We have precision to 38.
  coerce_tests! :test_schema_dump_keeps_large_precision_integer_columns_as_decimal
  def test_schema_dump_keeps_large_precision_integer_columns_as_decimal_coerced
    output = standard_dump
    assert_match %r{t.decimal\s+"atoms_in_universe",\s+precision: 38}, output
  end

  # This is a poorly written test and really does not catch the bottom'ness it is meant to. Ours throw it off.
  coerce_tests! :test_foreign_keys_are_dumped_at_the_bottom_to_circumvent_dependency_issues

  # Fall through false positive with no filter.
  coerce_tests! :test_schema_dumps_partial_indices
  def test_schema_dumps_partial_indices_coerced
    index_definition = standard_dump.split(/\n/).grep(/t.index.*company_partial_index/).first.strip
    assert_equal 't.index ["firm_id", "type"], name: "company_partial_index", where: "([rating]>(10))"', index_definition
  end

  # We do not quote the 2.78 string default.
  coerce_tests! :test_schema_dump_includes_decimal_options
  def test_schema_dump_includes_decimal_options_coerced
    output = dump_all_table_schema([/^[^n]/])
    assert_match %r{precision: 3,[[:space:]]+scale: 2,[[:space:]]+default: 2\.78}, output
  end

  # Tests are not about a specific adapter.
  coerce_tests! :test_do_not_dump_foreign_keys_when_bypassed_by_config

  # SQL Server formats the check constraint expression differently.
  coerce_tests! :test_schema_dumps_check_constraints
  def test_schema_dumps_check_constraints_coerced
    constraint_definition = dump_table_schema("products").split(/\n/).grep(/t.check_constraint.*products_price_check/).first.strip
    assert_equal 't.check_constraint "[price]>[discounted_price]", name: "products_price_check"', constraint_definition
  end
end

class SchemaDumperDefaultsTest < ActiveRecord::TestCase
  # These date formats do not match ours. We got these covered in our dumper tests.
  coerce_tests! :test_schema_dump_defaults_with_universally_supported_types

  # SQL Server uses different method to generate a UUID than Rails test uses. Reimplemented the
  # test in 'SchemaDumperDefaultsCoerceTest'.
  coerce_tests! :test_schema_dump_with_text_column
end

class SchemaDumperDefaultsCoerceTest < ActiveRecord::TestCase
  include SchemaDumpingHelper

  setup do
    @connection = ActiveRecord::Base.connection
    @connection.create_table :dump_defaults, force: true do |t|
      t.string   :string_with_default,   default: "Hello!"
      t.date     :date_with_default,     default: "2014-06-05"
      t.datetime :datetime_with_default, default: "2014-06-05 07:17:04"
      t.time     :time_with_default,     default: "07:17:04"
      t.decimal  :decimal_with_default,  default: "1234567890.0123456789", precision: 20, scale: 10

      t.text     :text_with_default, default: "John' Doe"
      t.text     :uuid, default: -> { "newid()" }
    end
  end

  def test_schema_dump_with_text_column_coerced
    output = dump_table_schema("dump_defaults")

    assert_match %r{t\.text\s+"text_with_default",.*?default: "John' Doe"}, output
    assert_match %r{t\.text\s+"uuid",.*?default: -> \{ "newid\(\)" \}}, output
  end
end

class TestAdapterWithInvalidConnection < ActiveRecord::TestCase
  # We trust Rails on this since we do not want to install mysql.
  coerce_tests! %r{inspect on Model class does not raise}
end

require "models/topic"
class TransactionTest < ActiveRecord::TestCase
  # SQL Server does not have query for release_savepoint.
  coerce_tests! :test_releasing_named_savepoints
  def test_releasing_named_savepoints_coerced
    Topic.transaction do
      Topic.connection.materialize_transactions

      Topic.connection.create_savepoint("another")
      Topic.connection.release_savepoint("another")
      # We do not have a notion of releasing, so this does nothing vs raise an error.
      Topic.connection.release_savepoint("another")
    end
  end

  # SQL Server does not have query for release_savepoint.
  coerce_tests! :test_nested_transactions_after_disable_lazy_transactions
  def test_nested_transactions_after_disable_lazy_transactions_coerced
    Topic.connection.disable_lazy_transactions!

    capture_sql do
      # RealTransaction (begin..commit)
      Topic.transaction(requires_new: true) do
        # ResetParentTransaction (no queries)
        Topic.transaction(requires_new: true) do
          Topic.delete_all
          # SavepointTransaction (savepoint..release)
          Topic.transaction(requires_new: true) do
            # ResetParentTransaction (no queries)
            Topic.transaction(requires_new: true) do
              # no-op
            end
          end
        end
        Topic.delete_all
      end
    end

    actual_queries = ActiveRecord::SQLCounter.log_all

    expected_queries = [
      /BEGIN/i,
      /DELETE/i,
      /^SAVE TRANSACTION/i,
      /DELETE/i,
      /COMMIT/i,
    ]

    assert_equal expected_queries.size, actual_queries.size
    expected_queries.zip(actual_queries) do |expected, actual|
      assert_match expected, actual
    end
  end

  # SQL Server does not have query for release_savepoint.
  coerce_tests! :test_nested_transactions_skip_excess_savepoints
  def test_nested_transactions_skip_excess_savepoints_coerced
    capture_sql do
      # RealTransaction (begin..commit)
      Topic.transaction(requires_new: true) do
        # ResetParentTransaction (no queries)
        Topic.transaction(requires_new: true) do
          Topic.delete_all
          # SavepointTransaction (savepoint..release)
          Topic.transaction(requires_new: true) do
            # ResetParentTransaction (no queries)
            Topic.transaction(requires_new: true) do
              Topic.delete_all
            end
          end
        end
        Topic.delete_all
      end
    end

    actual_queries = ActiveRecord::SQLCounter.log_all

    expected_queries = [
      /BEGIN/i,
      /DELETE/i,
      /^SAVE TRANSACTION/i,
      /DELETE/i,
      /DELETE/i,
      /COMMIT/i,
    ]

    assert_equal expected_queries.size, actual_queries.size
    expected_queries.zip(actual_queries) do |expected, actual|
      assert_match expected, actual
    end
  end
end

require "models/tag"
class TransactionIsolationTest < ActiveRecord::TestCase
  # SQL Server will lock the table for counts even when both
  # connections are `READ COMMITTED`. So we bypass with `READPAST`.
  coerce_tests! %r{read committed}
  test "read committed coerced" do
    Tag.transaction(isolation: :read_committed) do
      assert_equal 0, Tag.count
      Tag2.transaction do
        Tag2.create
        assert_equal 0, Tag.lock("WITH(READPAST)").count
      end
    end
    assert_equal 1, Tag.count
  end

  # I really need some help understanding this one.
  coerce_tests! %r{repeatable read}
end

require "models/book"
class ViewWithPrimaryKeyTest < ActiveRecord::TestCase
  # We have a few view tables. use includes vs equality.
  coerce_tests! :test_views
  def test_views_coerced
    assert_includes @connection.views, Ebook.table_name
  end

  # We do better than ActiveRecord and find the views PK.
  coerce_tests! :test_does_not_assume_id_column_as_primary_key
  def test_does_not_assume_id_column_as_primary_key_coerced
    model = Class.new(ActiveRecord::Base) { self.table_name = "ebooks" }
    assert_equal "id", model.primary_key
  end
end

class ViewWithoutPrimaryKeyTest < ActiveRecord::TestCase
  # We have a few view tables. use includes vs equality.
  coerce_tests! :test_views
  def test_views_coerced
    assert_includes @connection.views, Paperback.table_name
  end
end

require "models/author"
class YamlSerializationTest < ActiveRecord::TestCase
  coerce_tests! :test_types_of_virtual_columns_are_not_changed_on_round_trip
  def test_types_of_virtual_columns_are_not_changed_on_round_trip_coerced
    author = Author.select("authors.*, 5 as posts_count").first
    dumped_author = YAML.dump(author)
    dumped = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(dumped_author) : YAML.load(dumped_author)
    assert_equal 5, author.posts_count
    assert_equal 5, dumped.posts_count
  end
end

class DateTimePrecisionTest < ActiveRecord::TestCase
  # Original test had `7` which we support vs `8` which we use.
  coerce_tests! :test_invalid_datetime_precision_raises_error
  def test_invalid_datetime_precision_raises_error_coerced
    assert_raises ActiveRecord::ActiveRecordError do
      @connection.create_table(:foos, force: true) do |t|
        t.timestamps precision: 8
      end
    end
  end

  # datetime is rounded to increments of .000, .003, or .007 seconds
  coerce_tests! :test_datetime_precision_is_truncated_on_assignment
  def test_datetime_precision_is_truncated_on_assignment_coerced
    @connection.create_table(:foos, force: true)
    @connection.add_column :foos, :created_at, :datetime, precision: 0
    @connection.add_column :foos, :updated_at, :datetime, precision: 6

    time = ::Time.now.change(nsec: 123456789)
    foo = Foo.new(created_at: time, updated_at: time)

    assert_equal 0, foo.created_at.nsec
    assert_equal 123457000, foo.updated_at.nsec

    foo.save!
    foo.reload

    assert_equal 0, foo.created_at.nsec
    assert_equal 123457000, foo.updated_at.nsec
  end
end

class TimePrecisionTest < ActiveRecord::TestCase
  # datetime is rounded to increments of .000, .003, or .007 seconds
  coerce_tests! :test_time_precision_is_truncated_on_assignment
  def test_time_precision_is_truncated_on_assignment_coerced
    @connection.create_table(:foos, force: true)
    @connection.add_column :foos, :start,  :time, precision: 0
    @connection.add_column :foos, :finish, :time, precision: 6

    time = ::Time.now.change(nsec: 123456789)
    foo = Foo.new(start: time, finish: time)

    assert_equal 0, foo.start.nsec
    assert_equal 123457000, foo.finish.nsec

    foo.save!
    foo.reload

    assert_equal 0, foo.start.nsec
    assert_equal 123457000, foo.finish.nsec
  end

  # SQL Server uses default precision for time.
  coerce_tests! :test_no_time_precision_isnt_truncated_on_assignment
end

class DefaultNumbersTest < ActiveRecord::TestCase
  # We do better with native types and do not return strings for everything.
  coerce_tests! :test_default_positive_integer
  def test_default_positive_integer_coerced
    record = DefaultNumber.new
    assert_equal 7, record.positive_integer
    assert_equal 7, record.positive_integer_before_type_cast
  end

  # We do better with native types and do not return strings for everything.
  coerce_tests! :test_default_negative_integer
  def test_default_negative_integer_coerced
    record = DefaultNumber.new
    assert_equal (-5), record.negative_integer
    assert_equal (-5), record.negative_integer_before_type_cast
  end

  # We do better with native types and do not return strings for everything.
  coerce_tests! :test_default_decimal_number
  def test_default_decimal_number_coerced
    record = DefaultNumber.new
    assert_equal BigDecimal("2.78"), record.decimal_number
    assert_equal 2.78, record.decimal_number_before_type_cast
  end
end

module ActiveRecord
  class CollectionCacheKeyTest < ActiveRecord::TestCase
    # Will trust rails has this sorted since you cant offset without a limit.
    coerce_tests! %r{with offset which return 0 rows}
  end
end

module ActiveRecord
  class CacheKeyTest < ActiveRecord::TestCase
    # Like Mysql2 and PostgreSQL, SQL Server doesn't return a string value for updated_at. In the Rails tests
    # the tests are skipped if adapter is Mysql2 or PostgreSQL.
    coerce_tests! %r{cache_version is the same when it comes from the DB or from the user}
    coerce_tests! %r{cache_version does NOT call updated_at when value is from the database}
    coerce_tests! %r{cache_version does not truncate zeros when timestamp ends in zeros}
  end
end

require "models/book"
module ActiveRecord
  class StatementCacheTest < ActiveRecord::TestCase
    # Getting random failures.
    coerce_tests! :test_find_does_not_use_statement_cache_if_table_name_is_changed

    # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
    coerce_tests! :test_statement_cache_values_differ
    def test_statement_cache_values_differ_coerced
      Book.connection.remove_index(:books, column: [:author_id, :name])

      original_test_statement_cache_values_differ
    ensure
      Book.where(author_id: nil, name: 'my book').delete_all
      Book.connection.add_index(:books, [:author_id, :name], unique: true)
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class SchemaCacheTest < ActiveRecord::TestCase
      # Tests fail on Windows AppVeyor CI with 'Permission denied' error when renaming file during `File.atomic_write` call.
      coerce_tests! :test_yaml_dump_and_load, :test_yaml_dump_and_load_with_gzip if RbConfig::CONFIG["host_os"] =~ /mswin|mingw/

      # Ruby 2.5 and 2.6 have issues to marshal Time before 1900. 2012.sql has one column with default value 1753
      coerce_tests! :test_marshal_dump_and_load_with_gzip, :test_marshal_dump_and_load_via_disk

      # Tests fail on Windows AppVeyor CI with 'Permission denied' error when renaming file during `File.atomic_write` call.
      unless RbConfig::CONFIG["host_os"] =~ /mswin|mingw/
        def test_marshal_dump_and_load_with_gzip_coerced
          with_marshable_time_defaults { original_test_marshal_dump_and_load_with_gzip }
        end
        def test_marshal_dump_and_load_via_disk_coerced
          with_marshable_time_defaults { original_test_marshal_dump_and_load_via_disk }
        end
      end

      private

      def with_marshable_time_defaults
        # Detect problems
        if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.7")
          column = @connection.columns(:sst_datatypes).find { |c| c.name == "datetime" }
          current_default = column.default if column.default.is_a?(Time) && column.default.year < 1900
        end

        # Correct problems
        if current_default.present?
          @connection.change_column_default(:sst_datatypes, :datetime, current_default.dup.change(year: 1900))
        end

        # Run original test
        yield
      ensure
        # Revert changes
        @connection.change_column_default(:sst_datatypes, :datetime, current_default) if current_default.present?
      end

      # We need to give the full path for this to work.
      undef_method :schema_dump_path
      def schema_dump_path
        File.join(ARTest::SQLServer.root_activerecord, "test/assets/schema_dump_5_1.yml")
      end
    end
  end
end

require "models/post"
require "models/comment"
class UnsafeRawSqlTest < ActiveRecord::TestCase
  fixtures :posts

  # Use LEN() instead of LENGTH() function.
  coerce_tests! %r{order: always allows Arel}
  test "order: always allows Arel" do
    titles = Post.order(Arel.sql("len(title)")).pluck(:title)

    assert_not_empty titles
  end

  # Use LEN() instead of LENGTH() function.
  coerce_tests! %r{pluck: always allows Arel}
  test "pluck: always allows Arel" do
    excepted_values = Post.includes(:comments).pluck(:title).map { |title| [title, title.size] }
    values = Post.includes(:comments).pluck(:title, Arel.sql("len(title)"))

    assert_equal excepted_values, values
  end

  # Use LEN() instead of LENGTH() function.
  coerce_tests! %r{order: allows valid Array arguments}
  test "order: allows valid Array arguments" do
    ids_expected = Post.order(Arel.sql("author_id, len(title)")).pluck(:id)

    ids = Post.order(["author_id", "len(title)"]).pluck(:id)

    assert_equal ids_expected, ids
  end

  # Use LEN() instead of LENGTH() function.
  coerce_tests! %r{order: allows nested functions}
  test "order: allows nested functions" do
    ids_expected = Post.order(Arel.sql("author_id, len(trim(title))")).pluck(:id)

    # $DEBUG = true
    ids = Post.order("author_id, len(trim(title))").pluck(:id)

    assert_equal ids_expected, ids
  end

  # Use LEN() instead of LENGTH() function.
  coerce_tests! %r{pluck: allows nested functions}
  test "pluck: allows nested functions" do
    title_lengths_expected = Post.pluck(Arel.sql("len(trim(title))"))

    title_lengths = Post.pluck("len(trim(title))")

    assert_equal title_lengths_expected, title_lengths
  end

  test "order: allows string column names that are quoted" do
    ids_expected = Post.order(Arel.sql("id")).pluck(:id)

    ids = Post.order("[id]").pluck(:id)

    assert_equal ids_expected, ids
  end

  test "order: allows string column names that are quoted with table" do
    ids_expected = Post.order(Arel.sql("id")).pluck(:id)

    ids = Post.order("[posts].[id]").pluck(:id)

    assert_equal ids_expected, ids
  end

  test "order: allows string column names that are quoted with table and user" do
    ids_expected = Post.order(Arel.sql("id")).pluck(:id)

    ids = Post.order("[dbo].[posts].[id]").pluck(:id)

    assert_equal ids_expected, ids
  end

  test "order: allows string column names that are quoted with table, user and database" do
    ids_expected = Post.order(Arel.sql("id")).pluck(:id)

    ids = Post.order("[activerecord_unittest].[dbo].[posts].[id]").pluck(:id)

    assert_equal ids_expected, ids
  end

  test "pluck: allows string column name that are quoted" do
    titles_expected = Post.pluck(Arel.sql("title"))

    titles = Post.pluck("[title]")

    assert_equal titles_expected, titles
  end

  test "pluck: allows string column name that are quoted with table" do
    titles_expected = Post.pluck(Arel.sql("title"))

    titles = Post.pluck("[posts].[title]")

    assert_equal titles_expected, titles
  end

  test "pluck: allows string column name that are quoted with table and user" do
    titles_expected = Post.pluck(Arel.sql("title"))

    titles = Post.pluck("[dbo].[posts].[title]")

    assert_equal titles_expected, titles
  end

  test "pluck: allows string column name that are quoted with table, user and database" do
    titles_expected = Post.pluck(Arel.sql("title"))

    titles = Post.pluck("[activerecord_unittest].[dbo].[posts].[title]")

    assert_equal titles_expected, titles
  end

  # Collation name should not be quoted. Hardcoded values for different adapters.
  coerce_tests! %r{order: allows valid arguments with COLLATE}
  test "order: allows valid arguments with COLLATE" do
    collation_name = "Latin1_General_CS_AS_WS"

    ids_expected = Post.order(Arel.sql(%Q'author_id, title COLLATE #{collation_name} DESC')).pluck(:id)

    ids = Post.order(["author_id", %Q'title COLLATE #{collation_name} DESC']).pluck(:id)

    assert_equal ids_expected, ids
  end
end

class ReservedWordTest < ActiveRecord::TestCase
  coerce_tests! :test_change_columns
  def test_change_columns_coerced
    assert_nothing_raised { @connection.change_column_default(:group, :order, "whatever") }
    assert_nothing_raised { @connection.change_column("group", "order", :text) }
    assert_nothing_raised { @connection.change_column_null("group", "order", true) }
    assert_nothing_raised { @connection.rename_column(:group, :order, :values) }
  end
end

class OptimisticLockingTest < ActiveRecord::TestCase
  # We do not allow updating identities, but we can test using a non-identity key
  coerce_tests! :test_update_with_dirty_primary_key
  def test_update_with_dirty_primary_key_coerced
    assert_raises(ActiveRecord::RecordNotUnique) do
      record = StringKeyObject.find("record1")
      record.id = "record2"
      record.save!
    end

    record = StringKeyObject.find("record1")
    record.id = "record42"
    record.save!

    assert StringKeyObject.find("record42")
    assert_raises(ActiveRecord::RecordNotFound) do
      StringKeyObject.find("record1")
    end
  end
end

class RelationMergingTest < ActiveRecord::TestCase
  # Use nvarchar string (N'') in assert
  coerce_tests! :test_merging_with_order_with_binds
  def test_merging_with_order_with_binds_coerced
    relation = Post.all.merge(Post.order([Arel.sql("title LIKE ?"), "%suffix"]))
    assert_equal ["title LIKE N'%suffix'"], relation.order_values
  end

  # Same as original but change first regexp to match sp_executesql binding syntax
  coerce_tests! :test_merge_doesnt_duplicate_same_clauses
  def test_merge_doesnt_duplicate_same_clauses_coerced
    david, mary, bob = authors(:david, :mary, :bob)

    non_mary_and_bob = Author.where.not(id: [mary, bob])

    author_id = Author.connection.quote_table_name("authors.id")
    assert_sql(/WHERE #{Regexp.escape(author_id)} NOT IN \((@\d), \g<1>\)'/) do
      assert_equal [david], non_mary_and_bob.merge(non_mary_and_bob)
    end

    only_david = Author.where("#{author_id} IN (?)", david)

    assert_sql(/WHERE \(#{Regexp.escape(author_id)} IN \(1\)\)\z/) do
      assert_equal [david], only_david.merge(only_david)
    end
  end
end

module ActiveRecord
  class DatabaseTasksTruncateAllTest < ActiveRecord::TestCase
    # SQL Server does not allow truncation of tables that are referenced by foreign key
    # constraints. As this test truncates all tables we would need to remove all foreign
    # key constraints and then restore them afterwards to get this test to pass.
    coerce_tests! :test_truncate_tables
  end
end

require "models/book"
class EnumTest < ActiveRecord::TestCase
  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! %r{enums are distinct per class}
  test "enums are distinct per class coerced" do
    Book.connection.remove_index(:books, column: [:author_id, :name])

    send(:'original_enums are distinct per class')
  ensure
    Book.where(author_id: nil, name: nil).delete_all
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end

  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! %r{creating new objects with enum scopes}
  test "creating new objects with enum scopes coerced" do
    Book.connection.remove_index(:books, column: [:author_id, :name])

    send(:'original_creating new objects with enum scopes')
  ensure
    Book.where(author_id: nil, name: nil).delete_all
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end

  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! %r{enums are inheritable}
  test "enums are inheritable coerced" do
    Book.connection.remove_index(:books, column: [:author_id, :name])

    send(:'original_enums are inheritable')
  ensure
    Book.where(author_id: nil, name: nil).delete_all
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end

  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! %r{declare multiple enums at a time}
  test "declare multiple enums at a time coerced" do
    Book.connection.remove_index(:books, column: [:author_id, :name])

    send(:'original_declare multiple enums at a time')
  ensure
    Book.where(author_id: nil, name: nil).delete_all
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end

  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! %r{serializable\? with large number label}
  test "serializable? with large number label coerced" do
    Book.connection.remove_index(:books, column: [:author_id, :name])

    send(:'original_serializable\? with large number label')
  ensure
    Book.where(author_id: nil, name: nil).delete_all
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end
end

require "models/task"
class QueryCacheExpiryTest < ActiveRecord::TestCase
  # SQL Server does not support skipping or upserting duplicates.
  coerce_tests! :test_insert_all
  def test_insert_all_coerced
    assert_raises(ArgumentError, /does not support skipping duplicates/) do
      Task.cache { Task.insert({ starting: Time.now }) }
    end

    assert_called(ActiveRecord::Base.connection, :clear_query_cache, times: 2) do
      Task.cache { Task.insert_all!([{ starting: Time.now }]) }
    end

    assert_called(ActiveRecord::Base.connection, :clear_query_cache, times: 2) do
      Task.cache { Task.insert!({ starting: Time.now }) }
    end

    assert_called(ActiveRecord::Base.connection, :clear_query_cache, times: 2) do
      Task.cache { Task.insert_all!([{ starting: Time.now }]) }
    end

    assert_raises(ArgumentError, /does not support upsert/) do
      Task.cache { Task.upsert({ starting: Time.now }) }
    end

    assert_raises(ArgumentError, /does not support upsert/) do
      Task.cache { Task.upsert_all([{ starting: Time.now }]) }
    end
  end
end

require "models/citation"
class EagerLoadingTooManyIdsTest < ActiveRecord::TestCase
  fixtures :citations

  # Original Rails test fails with SQL Server error message "The query processor ran out of internal resources and
  # could not produce a query plan". This error goes away if you change database compatibility level to 110 (SQL 2012)
  # (see https://www.mssqltips.com/sqlservertip/5279/sql-server-error-query-processor-ran-out-of-internal-resources-and-could-not-produce-a-query-plan/).
  # However, you cannot change the compatibility level during a test. The purpose of the test is to ensure that an
  # unprepared statement is used if the number of values exceeds the adapter's `bind_params_length`. The coerced test
  # still does this as there will be 32,768 remaining citation records in the database and the `bind_params_length` of
  # adapter is 2,098.
  coerce_tests! :test_eager_loading_too_many_ids
  def test_eager_loading_too_many_ids_coerced
    # Remove excess records.
    Citation.limit(32768).order(id: :desc).delete_all

    # Perform test
    citation_count = Citation.count
    assert_sql(/WHERE \[citations\]\.\[id\] IN \(0, 1/) do
      assert_equal citation_count, Citation.eager_load(:citations).offset(0).size
    end
  end
end

class LogSubscriberTest < ActiveRecord::TestCase
  # Call original test from coerced test. Fixes issue on CI with Rails installed as a gem.
  coerce_tests! :test_verbose_query_logs
  def test_verbose_query_logs_coerced
    original_test_verbose_query_logs
  end

  # Bindings logged slightly differently.
  coerce_tests! :test_where_in_binds_logging_include_attribute_names
  def test_where_in_binds_logging_include_attribute_names_coerced
    Developer.where(id: [1, 2, 3, 4, 5]).load
    wait
    assert_match(%{@0 = 1, @1 = 2, @2 = 3, @3 = 4, @4 = 5  [["id", nil], ["id", nil], ["id", nil], ["id", nil], ["id", nil]]}, @logger.logged(:debug).last)
  end
end

class ReloadModelsTest < ActiveRecord::TestCase
  # Skip test on Windows. The number of arguments passed to `IO.popen` in
  # `activesupport/lib/active_support/testing/isolation.rb` exceeds what Windows can handle.
  coerce_tests! :test_has_one_with_reload if RbConfig::CONFIG["host_os"] =~ /mswin|mingw/
end

class MarshalSerializationTest < ActiveRecord::TestCase
  private

  undef_method :marshal_fixture_path
  def marshal_fixture_path(file_name)
    File.expand_path(
      "support/marshal_compatibility_fixtures/#{ActiveRecord::Base.connection.adapter_name}/#{file_name}.dump",
      ARTest::SQLServer.test_root_sqlserver
    )
  end
end

class NestedThroughAssociationsTest < ActiveRecord::TestCase
  # Same as original but replace order with "order(:id)" to ensure that assert_includes_and_joins_equal doesn't raise
  # "A column has been specified more than once in the order by list"
  # Example: original test generate queries like "ORDER BY authors.id, [authors].[id]". We don't support duplicate columns in the order list
  coerce_tests! :test_has_many_through_has_many_with_has_many_through_habtm_source_reflection_preload_via_joins, :test_has_many_through_has_and_belongs_to_many_with_has_many_source_reflection_preload_via_joins
  def test_has_many_through_has_many_with_has_many_through_habtm_source_reflection_preload_via_joins_coerced
    # preload table schemas
    Author.joins(:category_post_comments).first

    assert_includes_and_joins_equal(
      Author.where("comments.id" => comments(:does_it_hurt).id).order(:id),
      [authors(:david), authors(:mary)], :category_post_comments
    )
  end

  def test_has_many_through_has_and_belongs_to_many_with_has_many_source_reflection_preload_via_joins_coerced
    # preload table schemas
    Category.joins(:post_comments).first

    assert_includes_and_joins_equal(
      Category.where("comments.id" => comments(:more_greetings).id).order(:id),
      [categories(:general), categories(:technology)], :post_comments
    )
  end
end

class PreloaderTest < ActiveRecord::TestCase
  # Need to handle query parameters in SQL regex.
  coerce_tests! :test_preloads_has_many_on_model_with_a_composite_primary_key_through_id_attribute
  def test_preloads_has_many_on_model_with_a_composite_primary_key_through_id_attribute_coerced
    order = cpk_orders(:cpk_groceries_order_2)
    _shop_id, order_id = order.id
    order_agreements = Cpk::OrderAgreement.where(order_id: order_id).to_a

    assert_not_empty order_agreements
    assert_equal order_agreements.sort, order.order_agreements.sort

    loaded_order = nil
    sql = capture_sql do
      loaded_order = Cpk::Order.where(id: order_id).includes(:order_agreements).to_a.first
    end

    assert_equal 2, sql.size
    preload_sql = sql.last

    c = Cpk::OrderAgreement.connection
    order_id_column = Regexp.escape(c.quote_table_name("cpk_order_agreements.order_id"))
    order_id_constraint = /#{order_id_column} = @0.*@0 = \d+$/
    expectation = /SELECT.*WHERE.* #{order_id_constraint}/

    assert_match(expectation, preload_sql)
    assert_equal order_agreements.sort, loaded_order.order_agreements.sort
  end

  # Need to handle query parameters in SQL regex.
  coerce_tests! :test_preloads_belongs_to_a_composite_primary_key_model_through_id_attribute
  def test_preloads_belongs_to_a_composite_primary_key_model_through_id_attribute_coerced
    order_agreement = cpk_order_agreements(:order_agreement_three)
    order = cpk_orders(:cpk_groceries_order_2)
    assert_equal order, order_agreement.order

    loaded_order_agreement = nil
    sql = capture_sql do
      loaded_order_agreement = Cpk::OrderAgreement.where(id: order_agreement.id).includes(:order).to_a.first
    end

    assert_equal 2, sql.size
    preload_sql = sql.last

    c = Cpk::Order.connection
    order_id = Regexp.escape(c.quote_table_name("cpk_orders.id"))
    order_constraint = /#{order_id} = @0.*@0 = \d+$/
    expectation = /SELECT.*WHERE.* #{order_constraint}/

    assert_match(expectation, preload_sql)
    assert_equal order, loaded_order_agreement.order
  end
end

class BasePreventWritesTest < ActiveRecord::TestCase
  # SQL Server does not have query for release_savepoint
  coerce_tests! %r{an empty transaction does not raise if preventing writes}
  test "an empty transaction does not raise if preventing writes coerced" do
    ActiveRecord::Base.while_preventing_writes do
      assert_queries(1, ignore_none: true) do
        Bird.transaction do
          ActiveRecord::Base.connection.materialize_transactions
        end
      end
    end
  end
end

class MigratorTest < ActiveRecord::TestCase
  # Test fails on Windows AppVeyor CI for unknown reason.
  coerce_tests! :test_migrator_db_has_no_schema_migrations_table if RbConfig::CONFIG["host_os"] =~ /mswin|mingw/
end

class MultiDbMigratorTest < ActiveRecord::TestCase
  # Test fails on Windows AppVeyor CI for unknown reason.
  coerce_tests! :test_migrator_db_has_no_schema_migrations_table if RbConfig::CONFIG["host_os"] =~ /mswin|mingw/
end

require "models/book"
class FieldOrderedValuesTest < ActiveRecord::TestCase
  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! :test_in_order_of_with_enums_values
  def test_in_order_of_with_enums_values_coerced
    Book.connection.remove_index(:books, column: [:author_id, :name])

    original_test_in_order_of_with_enums_values
  ensure
    Book.where(author_id: nil, name: nil).delete_all
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end

  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! :test_in_order_of_with_string_column
  def test_in_order_of_with_string_column_coerced
    Book.connection.remove_index(:books, column: [:author_id, :name])

    original_test_in_order_of_with_string_column
  ensure
    Book.where(author_id: nil, name: nil).delete_all
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end

  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! :test_in_order_of_with_enums_keys
  def test_in_order_of_with_enums_keys_coerced
    Book.connection.remove_index(:books, column: [:author_id, :name])

    original_test_in_order_of_with_enums_keys
  ensure
    Book.where(author_id: nil, name: nil).delete_all
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end

  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! :test_in_order_of_with_nil
  def test_in_order_of_with_nil_coerced
    Book.connection.remove_index(:books, column: [:author_id, :name])

    original_test_in_order_of_with_nil
  ensure
    Book.where(author_id: nil, name: nil).delete_all
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end
end

require "models/dashboard"
class QueryLogsTest < ActiveRecord::TestCase
  # SQL requires double single-quotes.
  coerce_tests! :test_sql_commenter_format
  def test_sql_commenter_format_coerced
    ActiveRecord::QueryLogs.update_formatter(:sqlcommenter)
    assert_sql(%r{/\*application=''active_record''\*/}) do
      Dashboard.first
    end
  end

  # SQL requires double single-quotes.
  coerce_tests! :test_sqlcommenter_format_value
  def test_sqlcommenter_format_value_coerced
    ActiveRecord::QueryLogs.update_formatter(:sqlcommenter)

    ActiveRecord::QueryLogs.tags = [
      :application,
      { tracestate: "congo=t61rcWkgMzE,rojo=00f067aa0ba902b7", custom_proc: -> { "Joe's Shack" } },
    ]

    assert_sql(%r{custom_proc=''Joe%27s%20Shack'',tracestate=''congo%3Dt61rcWkgMzE%2Crojo%3D00f067aa0ba902b7''\*/}) do
      Dashboard.first
    end
  end

  # SQL requires double single-quotes.
  coerce_tests! :test_sqlcommenter_format_value_string_coercible
  def test_sqlcommenter_format_value_string_coercible_coerced
    ActiveRecord::QueryLogs.update_formatter(:sqlcommenter)

    ActiveRecord::QueryLogs.tags = [
      :application,
      { custom_proc: -> { 1234 } },
    ]

    assert_sql(%r{custom_proc=''1234''\*/}) do
      Dashboard.first
    end
  end

  # Invalid character encoding causes `ActiveRecord::StatementInvalid` error similar to Postgres.
  coerce_tests! :test_invalid_encoding_query
  def test_invalid_encoding_query_coerced
    ActiveRecord::QueryLogs.tags = [ :application ]
    assert_raises ActiveRecord::StatementInvalid do
      ActiveRecord::Base.connection.execute "select 1 as '\xFF'"
    end
  end
end

class InsertAllTest < ActiveRecord::TestCase
  # Same as original but using INSERTED.name as UPPER argument
  coerce_tests! :test_insert_all_returns_requested_sql_fields
  def test_insert_all_returns_requested_sql_fields_coerced
    skip unless supports_insert_returning?

    result = Book.insert_all! [{ name: "Rework", author_id: 1 }], returning: Arel.sql("UPPER(INSERTED.name) as name")
    assert_equal %w[ REWORK ], result.pluck("name")
  end
end

module ActiveRecord
  class Migration
    class InvalidOptionsTest < ActiveRecord::TestCase
      # Include the additional SQL Server migration options.
      undef_method :invalid_add_column_option_exception_message
      def invalid_add_column_option_exception_message(key)
        default_keys = [":limit", ":precision", ":scale", ":default", ":null", ":collation", ":comment", ":primary_key", ":if_exists", ":if_not_exists"]
        default_keys.concat([":is_identity"]) # SQL Server additional valid keys

        "Unknown key: :#{key}. Valid keys are: #{default_keys.join(", ")}"
      end
    end
  end
end

# SQL Server does not support upsert. Removed dependency on `insert_all` that uses upsert.
class ActiveRecord::Encryption::ConcurrencyTest < ActiveRecord::EncryptionTestCase
  undef_method :thread_encrypting_and_decrypting
  def thread_encrypting_and_decrypting(thread_label)
    posts = 100.times.collect { |index| EncryptedPost.create! title: "Article #{index} (#{thread_label})", body: "Body #{index} (#{thread_label})" }

    Thread.new do
      posts.each.with_index do |article, index|
        assert_encrypted_attribute article, :title, "Article #{index} (#{thread_label})"
        article.decrypt
        assert_not_encrypted_attribute article, :title, "Article #{index} (#{thread_label})"
      end
    end
  end
end

# Need to use `install_unregistered_type_fallback` instead of `install_unregistered_type_error` so that message-pack
# can read and write `ActiveRecord::ConnectionAdapters::SQLServer::Type::Data` objects.
class ActiveRecordMessagePackTest < ActiveRecord::TestCase
  private
  undef_method :serializer
  def serializer
    @serializer ||= ::MessagePack::Factory.new.tap do |factory|
      ActiveRecord::MessagePack::Extensions.install(factory)
      ActiveSupport::MessagePack::Extensions.install(factory)
      ActiveSupport::MessagePack::Extensions.install_unregistered_type_fallback(factory)
    end
  end
end

class StoreTest < ActiveRecord::TestCase
  # Set the attribute as JSON type for the `StoreTest#saved changes tracking for accessors with json column` test.
  Admin::User.attribute :json_options, ActiveRecord::Type::SQLServer::Json.new
end

class TestDatabasesTest < ActiveRecord::TestCase
  # Tests are not about a specific adapter.
  coerce_all_tests!
end

module ActiveRecord
  module ConnectionAdapters
    class ConnectionHandlersShardingDbTest  < ActiveRecord::TestCase
      # Tests are not about a specific adapter.
      coerce_all_tests!
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class ConnectionSwappingNestedTest < ActiveRecord::TestCase
      # Tests are not about a specific adapter.
      coerce_all_tests!
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class ConnectionHandlersMultiDbTest < ActiveRecord::TestCase
      # Tests are not about a specific adapter.
      coerce_tests! :test_switching_connections_via_handler
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class ConnectionHandlersMultiPoolConfigTest < ActiveRecord::TestCase
      # Tests are not about a specific adapter.
      coerce_all_tests!
    end
  end
end

module ActiveRecord
  class Migration
    class CheckConstraintTest < ActiveRecord::TestCase
      # SQL Server formats the check constraint expression differently.
      coerce_tests! :test_check_constraints
      def test_check_constraints_coerced
        check_constraints = @connection.check_constraints("products")
        assert_equal 1, check_constraints.size

        constraint = check_constraints.first
        assert_equal "products", constraint.table_name
        assert_equal "products_price_check", constraint.name
        assert_equal "[price]>[discounted_price]", constraint.expression
      end

      # SQL Server formats the check constraint expression differently.
      coerce_tests! :test_add_check_constraint
      def test_add_check_constraint_coerced
        @connection.add_check_constraint :trades, "quantity > 0"

        check_constraints = @connection.check_constraints("trades")
        assert_equal 1, check_constraints.size

        constraint = check_constraints.first
        assert_equal "trades", constraint.table_name
        assert_equal "chk_rails_2189e9f96c", constraint.name
        assert_equal "[quantity]>(0)", constraint.expression
      end

      # SQL Server formats the check constraint expression differently.
      coerce_tests! :test_remove_check_constraint
      def test_remove_check_constraint_coerced
        @connection.add_check_constraint :trades, "price > 0", name: "price_check"
        @connection.add_check_constraint :trades, "quantity > 0", name: "quantity_check"

        assert_equal 2, @connection.check_constraints("trades").size
        @connection.remove_check_constraint :trades, name: "quantity_check"
        assert_equal 1, @connection.check_constraints("trades").size

        constraint = @connection.check_constraints("trades").first
        assert_equal "trades", constraint.table_name
        assert_equal "price_check", constraint.name
        assert_equal "[price]>(0)", constraint.expression

        @connection.remove_check_constraint :trades, name: :price_check # name as a symbol
        assert_empty @connection.check_constraints("trades")
      end
    end
  end
end
