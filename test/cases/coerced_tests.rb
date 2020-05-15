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

  # Skip the test if database is case-insensitive.
  coerce_tests! :test_validate_case_sensitive_uniqueness_by_default
  def test_validate_case_sensitive_uniqueness_by_default_coerced
    database_collation = connection.select_one("SELECT collation_name FROM sys.databases WHERE name = 'activerecord_unittest'").values.first
    skip if database_collation.include?("_CI_")

    original_test_validate_case_sensitive_uniqueness_by_default_coerced
  end
end

require "models/event"
module ActiveRecord
  class AdapterTest < ActiveRecord::TestCase
    # I really don`t think we can support legacy binds.
    coerce_tests! :test_select_all_with_legacy_binds
    coerce_tests! :test_insert_update_delete_with_legacy_binds

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

    # Fix randomly failing test. The loading of the model's schema was affecting the test.
    coerce_tests! :test_errors_when_an_insert_query_is_called_while_preventing_writes
    def test_errors_when_an_insert_query_is_called_while_preventing_writes_coerced
      Subscriber.send(:load_schema!)
      original_test_errors_when_an_insert_query_is_called_while_preventing_writes
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
    ActiveRecord::Base.connection_handler.while_preventing_writes do
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

  # Are decimal, not integer.
  coerce_tests! :test_should_return_decimal_average_of_integer_field
  def test_should_return_decimal_average_of_integer_field_coerced
    value = Account.average(:id)
    assert_equal BigDecimal("3.0").to_s, BigDecimal(value).to_s
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
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class QuoteARBaseTest < ActiveRecord::TestCase
      # Use our date format.
      coerce_tests! :test_quote_ar_object
      def test_quote_ar_object_coerced
        value = DatetimePrimaryKey.new(id: @time)
        assert_equal "'02-14-2017 12:34:56.79'", @connection.quote(value)
      end

      # Use our date format.
      coerce_tests! :test_type_cast_ar_object
      def test_type_cast_ar_object_coerced
        value = DatetimePrimaryKey.new(id: @time)
        assert_equal "02-14-2017 12:34:56.79", @connection.type_cast(value)
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
  # We do not have do the DecimalWithoutScale type.
  coerce_tests! :test_add_table_with_decimals
  def test_add_table_with_decimals_coerced
    Person.connection.drop_table :big_numbers rescue nil
    assert !BigNumber.table_exists?
    GiveMeBigNumbers.up
    BigNumber.reset_column_information
    assert BigNumber.create(
      :bank_balance => 1586.43,
      :big_bank_balance => BigDecimal("1000234000567.95"),
      :world_population => 6000000000,
      :my_house_population => 3,
      :value_of_e => BigDecimal("2.7182818284590452353602875")
    )
    b = BigNumber.first
    assert_not_nil b
    assert_not_nil b.bank_balance
    assert_not_nil b.big_bank_balance
    assert_not_nil b.world_population
    assert_not_nil b.my_house_population
    assert_not_nil b.value_of_e
    assert_kind_of BigDecimal, b.world_population
    assert_equal "6000000000.0", b.world_population.to_s
    assert_kind_of Integer, b.my_house_population
    assert_equal 3, b.my_house_population
    assert_kind_of BigDecimal, b.bank_balance
    assert_equal BigDecimal("1586.43"), b.bank_balance
    assert_kind_of BigDecimal, b.big_bank_balance
    assert_equal BigDecimal("1000234000567.95"), b.big_bank_balance
    GiveMeBigNumbers.down
    assert_raise(ActiveRecord::StatementInvalid) { BigNumber.first }
  end

  # For some reason our tests set Rails.@_env which breaks test env switching.
  coerce_tests! :test_internal_metadata_stores_environment_when_other_data_exists
  coerce_tests! :test_internal_metadata_stores_environment
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

  class DatabaseTasksDumpSchemaCacheTest < ActiveRecord::TestCase
    # Skip this test with /tmp/my_schema_cache.yml path on Windows.
    coerce_tests! :test_dump_schema_cache if RbConfig::CONFIG["host_os"] =~ /mswin|mingw/
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

  # Use our escaped format in assertion.
  coerce_tests! :test_with_abstract_class_scope_should_be_executed_in_correct_context
  def test_with_abstract_class_scope_should_be_executed_in_correct_context_coerced
    vegetarian_pattern, gender_pattern = [/[lions].[is_vegetarian]/, /[lions].[gender]/]
    assert_match vegetarian_pattern, Lion.all.to_sql
    assert_match gender_pattern, Lion.female.to_sql
  end
end

require "models/post"
require "models/subscriber"
class EachTest < ActiveRecord::TestCase
  # Quoting in tests does not cope with bracket quoting.
  coerce_tests! :test_find_in_batches_should_quote_batch_order
  def test_find_in_batches_should_quote_batch_order_coerced
    Post.connection
    assert_sql(/ORDER BY \[posts\]\.\[id\]/) do
      Post.find_in_batches(:batch_size => 1) do |batch|
        assert_kind_of Array, batch
        assert_kind_of Post, batch.first
      end
    end
  end

  # Quoting in tests does not cope with bracket quoting.
  coerce_tests! :test_in_batches_should_quote_batch_order
  def test_in_batches_should_quote_batch_order_coerced
    Post.connection
    assert_sql(/ORDER BY \[posts\]\.\[id\]/) do
      Post.in_batches(of: 1) do |relation|
        assert_kind_of ActiveRecord::Relation, relation
        assert_kind_of Post, relation.first
      end
    end
  end
end

class EagerAssociationTest < ActiveRecord::TestCase
  # Use LEN() vs length() function.
  coerce_tests! :test_count_with_include
  def test_count_with_include_coerced
    assert_equal 3, authors(:david).posts_with_comments.where("LEN(comments.body) > 15").references(:comments).count
  end

  # Use TOP (1) in scope vs limit 1.
  coerce_tests! %r{including association based on sql condition and no database column}
end

require "models/topic"
class FinderTest < ActiveRecord::TestCase
  # We have implicit ordering, via FETCH.
  coerce_tests! %r{doesn't have implicit ordering},
                :test_find_doesnt_have_implicit_ordering

  # Square brackets around column name
  coerce_tests! :test_exists_does_not_select_columns_without_alias
  def test_exists_does_not_select_columns_without_alias_coerced
    assert_sql(/SELECT\s+1 AS one FROM \[topics\].*OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY.*@0 = 1/i) do
      Topic.exists?
    end
  end

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
end

module ActiveRecord
  class Migration
    class ForeignKeyTest < ActiveRecord::TestCase
      # We do not support :restrict.
      coerce_tests! :test_add_on_delete_restrict_foreign_key
      def test_add_on_delete_restrict_foreign_key_coerced
        assert_raises ArgumentError do
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", on_delete: :restrict
        end
        assert_raises ArgumentError do
          @connection.add_foreign_key :astronauts, :rockets, column: "rocket_id", on_update: :restrict
        end
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

require "models/company"
class InheritanceTest < ActiveRecord::TestCase
  # Rails test required inserting to a identity column.
  coerce_tests! :test_a_bad_type_column
  def test_a_bad_type_column_coerced
    Company.connection.with_identity_insert_enabled("companies") do
      Company.connection.insert "INSERT INTO companies (id, #{QUOTED_TYPE}, name) VALUES(100, 'bad_class!', 'Not happening')"
    end
    assert_raise(ActiveRecord::SubclassNotFound) { Company.find(100) }
  end

  # Use Square brackets around column name
  coerce_tests! :test_eager_load_belongs_to_primary_key_quoting
  def test_eager_load_belongs_to_primary_key_quoting_coerced
    Account.connection
    assert_sql(/\[companies\]\.\[id\] = @0.* @0 = 1/) do
      Account.all.merge!(:includes => :firm).find(1)
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

  # Same as original test except that we expect one query to be performed to retrieve the table's primary key.
  # When we generate the SQL for the `find` it includes ordering on the primary key. If we reset the column
  # information then the primary key needs to be retrieved from the database again to generate the SQL causing the
  # original test's `assert_no_queries` assertion to fail. Assert that the query was to get the primary key.
  coerce_tests! :test_query_cached_even_when_types_are_reset
  def test_query_cached_even_when_types_are_reset_coerced
    Task.cache do
      # Warm the cache
      Task.find(1)

      # Preload the type cache again (so we don't have those queries issued during our assertions)
      Task.connection.send(:reload_type_map)

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
  # Use LEN vs LENGTH function.
  coerce_tests! :test_reverse_order_with_function
  def test_reverse_order_with_function_coerced
    topics = Topic.order(Arel.sql("LEN(title)")).reverse_order
    assert_equal topics(:second).title, topics.first.title
  end

  # Use LEN vs LENGTH function.
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
    assert sql_log.none? { |sql| /order by [posts].[title]/i.match?(sql) }, "ORDER BY title was used in the query: #{sql_log}"
    assert sql_log.all?  { |sql| /order by \[posts\]\.\[id\]/i.match?(sql) }, "default ORDER BY ID was not used in the query: #{sql_log}"
  end

  # We have implicit ordering, via FETCH.
  coerce_tests! :test_reorder_with_first
  def test_reorder_with_first_coerced
    sql_log = capture_sql do
      assert Post.order(:title).reorder(nil).first
    end
    assert sql_log.none? { |sql| /order by [posts].[title]/i.match?(sql) }, "ORDER BY title was used in the query: #{sql_log}"
    assert sql_log.all?  { |sql| /order by \[posts\]\.\[id\]/i.match?(sql) }, "default ORDER BY ID was not used in the query: #{sql_log}"
  end

  # We are not doing order duplicate removal anymore.
  coerce_tests! :test_order_using_scoping

  # We are not doing order duplicate removal anymore.
  coerce_tests! :test_default_scope_order_with_scope_order

  # Leave it up to users to format selects/functions so HAVING works correctly.
  coerce_tests! :test_multiple_where_and_having_clauses
  coerce_tests! :test_having_with_binds_for_both_where_and_having

  # Find any limit via our expression.
  coerce_tests! %r{relations don't load all records in #inspect}
  def test_relations_dont_load_all_records_in_inspect_coerced
    assert_sql(/NEXT @0 ROWS.*@0 = \d+/) do
      Post.all.inspect
    end
  end

  # I wanted to add `.order("author_id")` scope to avoid error: Column "posts.id" is invalid in the ORDER BY
  # However, this pull request on Rails core drops order on exists relation. https://github.com/rails/rails/pull/28699
  # so we are skipping all together.
  coerce_tests! :test_empty_complex_chained_relations

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

  # Use LEN() vs length() function.
  coerce_tests! :test_reverse_arel_assoc_order_with_function
  def test_reverse_arel_assoc_order_with_function_coerced
    topics = Topic.order(Arel.sql("LEN(title)") => :asc).reverse_order
    assert_equal topics(:second).title, topics.first.title
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
end

class SchemaDumperTest < ActiveRecord::TestCase
  # We have precision to 38.
  coerce_tests! :test_schema_dump_keeps_large_precision_integer_columns_as_decimal
  def test_schema_dump_keeps_large_precision_integer_columns_as_decimal_coerced
    output = standard_dump
    assert_match %r{t.decimal\s+"atoms_in_universe",\s+precision: 38}, output
  end

  # This is a poorly written test and really does not catch the bottom'ness it is meant too. Ours throw it off.
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
end

class SchemaDumperDefaultsTest < ActiveRecord::TestCase
  # These date formats do not match ours. We got these covered in our dumper tests.
  coerce_tests! :test_schema_dump_defaults_with_universally_supported_types
end

class TestAdapterWithInvalidConnection < ActiveRecord::TestCase
  # We trust Rails on this since we do not want to install mysql.
  coerce_tests! %r{inspect on Model class does not raise}
end

require "models/topic"
class TransactionTest < ActiveRecord::TestCase
  # SQL Server does not have query for release_savepoint
  coerce_tests! :test_releasing_named_savepoints
  def test_releasing_named_savepoints_coerced
    Topic.transaction do
      Topic.connection.create_savepoint("another")
      Topic.connection.release_savepoint("another")
      # We do not have a notion of releasing, so this does nothing vs raise an error.
      Topic.connection.release_savepoint("another")
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
    dumped = YAML.load(YAML.dump(author))
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
    assert_equal -5, record.negative_integer
    assert_equal -5, record.negative_integer_before_type_cast
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
      Book.connection.add_index(:books, [:author_id, :name], unique: true)
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class SchemaCacheTest < ActiveRecord::TestCase
      private

      # We need to give the full path for this to work.
      def schema_dump_path
        File.join ARTest::SQLServer.root_activerecord, "test/assets/schema_dump_5_1.yml"
      end
    end
  end
end

class UnsafeRawSqlTest < ActiveRecord::TestCase
  # Use LEN() vs length() function.
  coerce_tests! %r{order: always allows Arel}
  test "order: always allows Arel" do
    ids_depr     = with_unsafe_raw_sql_deprecated { Post.order(Arel.sql("len(title)")).pluck(:title) }
    ids_disabled = with_unsafe_raw_sql_disabled   { Post.order(Arel.sql("len(title)")).pluck(:title) }

    assert_equal ids_depr, ids_disabled
  end

  # Use LEN() vs length() function.
  coerce_tests! %r{pluck: always allows Arel}
  test "pluck: always allows Arel" do
    values_depr     = with_unsafe_raw_sql_deprecated { Post.includes(:comments).pluck(:title, Arel.sql("len(title)")) }
    values_disabled = with_unsafe_raw_sql_disabled   { Post.includes(:comments).pluck(:title, Arel.sql("len(title)")) }

    assert_equal values_depr, values_disabled
  end

  # Use LEN() vs length() function.
  coerce_tests! %r{order: allows valid Array arguments}
  test "order: allows valid Array arguments" do
    ids_expected = Post.order(Arel.sql("author_id, len(title)")).pluck(:id)

    ids_depr     = with_unsafe_raw_sql_deprecated { Post.order(["author_id", "len(title)"]).pluck(:id) }
    ids_disabled = with_unsafe_raw_sql_disabled   { Post.order(["author_id", "len(title)"]).pluck(:id) }

    assert_equal ids_expected, ids_depr
    assert_equal ids_expected, ids_disabled
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
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end

  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! %r{creating new objects with enum scopes}
  test "creating new objects with enum scopes coerced" do
    Book.connection.remove_index(:books, column: [:author_id, :name])

    send(:'original_creating new objects with enum scopes')
  ensure
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end

  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! %r{enums are inheritable}
  test "enums are inheritable coerced" do
    Book.connection.remove_index(:books, column: [:author_id, :name])

    send(:'original_enums are inheritable')
  ensure
    Book.connection.add_index(:books, [:author_id, :name], unique: true)
  end

  # Need to remove index as SQL Server considers NULLs on a unique-index to be equal unlike PostgreSQL/MySQL/SQLite.
  coerce_tests! %r{declare multiple enums at a time}
  test "declare multiple enums at a time coerced" do
    Book.connection.remove_index(:books, column: [:author_id, :name])

    send(:'original_declare multiple enums at a time')
  ensure
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
  # Original Rails test fails with SQL Server error message "The query processor ran out of internal resources and
  # could not produce a query plan". This error goes away if you change database compatibility level to 110 (SQL 2012)
  # (see https://www.mssqltips.com/sqlservertip/5279/sql-server-error-query-processor-ran-out-of-internal-resources-and-could-not-produce-a-query-plan/).
  # However, you cannot change the compatibility level during a test. The purpose of the test is to ensure that an
  # unprepared statement is used if the number of values exceeds the adapter's `bind_params_length`. The coerced test
  # still does this as there will be 32,768 remaining citation records in the database and the `bind_params_length` of
  # adapter is 2,098.
  coerce_tests! :test_eager_loading_too_may_ids
  def test_eager_loading_too_may_ids_coerced
    # Remove excess records.
    Citation.limit(32768).order(id: :desc).delete_all

    # Perform test
    citation_count = Citation.count
    assert_sql(/WHERE \(\[citations\]\.\[id\] IN \(0, 1/) do
      assert_equal citation_count, Citation.eager_load(:citations).offset(0).size
    end
  end
end

class LogSubscriberTest < ActiveRecord::TestCase
  # Call original test from coerced test. Fixes issue on CI with Rails installed as a gem.
  coerce_tests! :test_vebose_query_logs
  def test_vebose_query_logs_coerced
    original_test_vebose_query_logs
  end
end

class ActiveRecordSchemaTest < ActiveRecord::TestCase
  # Workaround for randomly failing test.
  coerce_tests! :test_has_primary_key
  def test_has_primary_key_coerced
    @schema_migration.reset_column_information
    original_test_has_primary_key
  end
end

module ActiveRecord
  module ConnectionAdapters
    class ReaperTest < ActiveRecord::TestCase
      # Coerce can be removed if Rails version > 6.0.3
      coerce_tests! :test_connection_pool_starts_reaper_in_fork unless Process.respond_to?(:fork)
    end
  end
end

class FixturesTest < ActiveRecord::TestCase
  # Skip test on Windows. Skip can be removed when Rails PR https://github.com/rails/rails/pull/39234 has been merged.
  coerce_tests! :test_binary_in_fixtures if RbConfig::CONFIG["host_os"] =~ /mswin|mingw/
end

class ReloadModelsTest < ActiveRecord::TestCase
  # Skip test on Windows. The number of arguements passed to `IO.popen` in
  # `activesupport/lib/active_support/testing/isolation.rb` exceeds what Windows can handle.
  coerce_tests! :test_has_one_with_reload if RbConfig::CONFIG["host_os"] =~ /mswin|mingw/
end
