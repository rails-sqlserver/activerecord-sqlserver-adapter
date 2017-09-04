require 'cases/helper_sqlserver'



require 'models/event'
class UniquenessValidationTest < ActiveRecord::TestCase
  # So sp_executesql swallows this exception. Run without prpared to see it.
  coerce_tests! :test_validate_uniqueness_with_limit
  def test_validate_uniqueness_with_limit_coerced
    connection.unprepared_statement do
      assert_raise(ActiveRecord::ValueTooLong) do
        Event.create(title: "abcdefgh")
      end
    end
  end

  # So sp_executesql swallows this exception. Run without prpared to see it.
  coerce_tests! :test_validate_uniqueness_with_limit_and_utf8
  def test_validate_uniqueness_with_limit_and_utf8_coerced
    connection.unprepared_statement do
      assert_raise(ActiveRecord::ValueTooLong) do
        Event.create(title: "一二三四五六七八")
      end
    end
  end
end




require 'models/event'
module ActiveRecord
  class AdapterTest < ActiveRecord::TestCase
    # I really dont think we can support legacy binds.
    coerce_tests! :test_select_all_with_legacy_binds

    # As far as I can tell, SQL Server does not support null bytes in strings.
    coerce_tests! :test_update_prepared_statement

    # So sp_executesql swallows this exception. Run without prpared to see it.
    coerce_tests! :test_value_limit_violations_are_translated_to_specific_exception
    def test_value_limit_violations_are_translated_to_specific_exception_coerced
      connection.unprepared_statement do
        error = assert_raises(ActiveRecord::ValueTooLong) do
          Event.create(title: 'abcdefgh')
        end
        assert_not_nil error.cause
      end
    end
  end
end




require 'models/topic'
class AttributeMethodsTest < ActiveRecord::TestCase
  coerce_tests! %r{typecast attribute from select to false}
  def test_typecast_attribute_from_select_to_false_coerced
    Topic.create(:title => 'Budget')
    topic = Topic.all.merge!(:select => "topics.*, IIF (1 = 2, 1, 0) as is_test").first
    assert !topic.is_test?
  end

  coerce_tests! %r{typecast attribute from select to true}
  def test_typecast_attribute_from_select_to_true_coerced
    Topic.create(:title => 'Budget')
    topic = Topic.all.merge!(:select => "topics.*, IIF (1 = 1, 1, 0) as is_test").first
    assert topic.is_test?
  end
end




class BasicsTest < ActiveRecord::TestCase
  coerce_tests! :test_column_names_are_escaped
  def test_column_names_are_escaped_coerced
    conn = ActiveRecord::Base.connection
    assert_equal '[t]]]', conn.quote_column_name('t]')
  end

  # We do not have do the DecimalWithoutScale type.
  coerce_tests! :test_numeric_fields
  coerce_tests! :test_numeric_fields_with_scale

  # Just like PostgreSQLAdapter does.
  coerce_tests! :test_respect_internal_encoding

  # Caused in Rails v4.2.5 by adding `firm_id` column in this http://git.io/vBfMs
  # commit. Trust Rails has this covered.
  coerce_tests! :test_find_keeps_multiple_group_values

  def test_update_date_time_attributes
    Time.use_zone("Eastern Time (US & Canada)") do
      topic = Topic.find(1)
      time = Time.zone.parse("2017-07-17 10:56")
      topic.update_attributes!(written_on: time)
      assert_equal(time, topic.written_on)
    end
  end

  def test_update_date_time_attributes_with_default_timezone_local
    with_env_tz 'America/New_York' do
      with_timezone_config default: :local do
        Time.use_zone("Eastern Time (US & Canada)") do
          topic = Topic.find(1)
          time = Time.zone.parse("2017-07-17 10:56")
          topic.update_attributes!(written_on: time)
          assert_equal(time, topic.written_on)
        end
      end
    end
  end
end




class BelongsToAssociationsTest < ActiveRecord::TestCase
  # Since @client.firm is a single first/top, and we use FETCH the order clause is used.
  coerce_tests! :test_belongs_to_does_not_use_order_by

  coerce_tests! :test_belongs_to_with_primary_key_joins_on_correct_column
  def test_belongs_to_with_primary_key_joins_on_correct_column_coerced
    sql = Client.joins(:firm_with_primary_key).to_sql
    assert_no_match(/\[firm_with_primary_keys_companies\]\.\[id\]/, sql)
    assert_match(/\[firm_with_primary_keys_companies\]\.\[name\]/, sql)
  end
end




module ActiveRecord
  class BindParameterTest < ActiveRecord::TestCase
    # Never finds `sql` since we use `EXEC sp_executesql` wrappers.
    coerce_tests! :test_binds_are_logged
  end
end




class CalculationsTest < ActiveRecord::TestCase
  # This fails randomly due to schema cache being lost?
  coerce_tests! :test_offset_is_kept
  def test_offset_is_kept_coerced
    Account.first
    queries = assert_sql { Account.offset(1).count }
    assert_equal 1, queries.length
    assert_match(/OFFSET/, queries.first)
  end

  # Are decimal, not integer.
  coerce_tests! :test_should_return_decimal_average_of_integer_field
  def test_should_return_decimal_average_of_integer_field_coerced
    value = Account.average(:id)
    assert_equal BigDecimal('3.0').to_s, BigDecimal(value).to_s
  end

  coerce_tests! :test_limit_is_kept
  def test_limit_is_kept_coerced
    queries = capture_sql_ss { Account.limit(1).count }
    assert_equal 1, queries.length
    queries.first.must_match %r{ORDER BY \[accounts\]\.\[id\] ASC OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY.*@0 = 1}
  end

  coerce_tests! :test_limit_with_offset_is_kept
  def test_limit_with_offset_is_kept_coerced
    queries = capture_sql_ss { Account.limit(1).offset(1).count }
    assert_equal 1, queries.length
    queries.first.must_match %r{ORDER BY \[accounts\]\.\[id\] ASC OFFSET @0 ROWS FETCH NEXT @1 ROWS ONLY.*@0 = 1, @1 = 1}
  end

  # Leave it up to users to format selects/functions so HAVING works correctly.
  coerce_tests! :test_having_with_strong_parameters
end



module ActiveRecord
  class Migration
    class ChangeSchemaTest < ActiveRecord::TestCase
       # We test these.
      coerce_tests! :test_create_table_with_bigint,
                    :test_create_table_with_defaults
    end
    class ChangeSchemaWithDependentObjectsTest < ActiveRecord::TestCase
      # In SQL Server you have to delete the tables yourself in the right order.
      coerce_tests! :test_create_table_with_force_cascade_drops_dependent_objects
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
        assert_equal "'02-14-2017 12:34:56.79'",  @connection.quote(value)
      end

      # Use our date format.
      coerce_tests! :test_type_cast_ar_object
      def test_type_cast_ar_object_coerced
        value = DatetimePrimaryKey.new(id: @time)
        assert_equal "02-14-2017 12:34:56.79",  @connection.type_cast(value)
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
        TestModel.columns_hash["description"].limit.must_equal 4000
      end
    end
  end
end




module ActiveRecord
  class Migration
    class ColumnsTest
      # Our defaults are real 70000 integers vs '70000' strings.
      coerce_tests! :test_rename_column_preserves_default_value_not_null
      def test_rename_column_preserves_default_value_not_null_coerced
        add_column 'test_models', 'salary', :integer, :default => 70000
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
        assert_equal 1, connection.indexes('test_models').size
        remove_column("test_models", "hat_size")
        assert_equal [], connection.indexes('test_models').map(&:name)
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
    assert_equal '6000000000.0', b.world_population.to_s
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
  coerce_tests! :test_migration_sets_internal_metadata_even_when_fully_migrated
  coerce_tests! :test_internal_metadata_stores_environment
end




class CoreTest < ActiveRecord::TestCase
  # I think fixtures are useing the wrong time zone and the `:first`
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
  end
end




module ActiveRecord
  class DatabaseTasksDumpSchemaCacheTest < ActiveRecord::TestCase
    # Skip this test with /tmp/my_schema_cache.yml path on Windows.
    coerce_tests! :test_dump_schema_cache if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
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




require 'models/post'
require 'models/subscriber'
class EachTest < ActiveRecord::TestCase
  # Quoting in tests does not cope with bracket quoting.
  coerce_tests! :test_find_in_batches_should_quote_batch_order
  def test_find_in_batches_should_quote_batch_order_coerced
    c = Post.connection
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
    c = Post.connection
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




require 'models/topic'
class FinderTest < ActiveRecord::TestCase
  coerce_tests! %r{doesn't have implicit ordering},
                :test_find_doesnt_have_implicit_ordering # We have implicit ordering, via FETCH.

  coerce_tests! :test_exists_does_not_select_columns_without_alias
  def test_exists_does_not_select_columns_without_alias_coerced
    assert_sql(/SELECT\s+1 AS one FROM \[topics\].*OFFSET 0 ROWS FETCH NEXT @0 ROWS ONLY.*@0 = 1/i) do
      Topic.exists?
    end
  end

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
    with_env_tz 'America/New_York' do
      with_timezone_config default: :local do
        topic = Topic.first
        assert_equal topic, Topic.where(written_on: topic.written_on.getutc).first
      end
    end
  end

  # Can not use array condition due to not finding right type and hence fractional second quoting.
  coerce_tests! :test_condition_local_time_interpolation_with_default_timezone_utc
  def test_condition_local_time_interpolation_with_default_timezone_utc_coerced
    with_env_tz 'America/New_York' do
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
end




require 'models/company'
class InheritanceTest < ActiveRecord::TestCase
  coerce_tests! :test_a_bad_type_column
  def test_a_bad_type_column_coerced
    Company.connection.with_identity_insert_enabled('companies') do
      Company.connection.insert "INSERT INTO companies (id, #{QUOTED_TYPE}, name) VALUES(100, 'bad_class!', 'Not happening')"
    end
    assert_raise(ActiveRecord::SubclassNotFound) { Company.find(100) }
  end

  coerce_tests! :test_eager_load_belongs_to_primary_key_quoting
  def test_eager_load_belongs_to_primary_key_quoting_coerced
    con = Account.connection
    assert_sql(/\[companies\]\.\[id\] = 1/) do
      Account.all.merge!(:includes => :firm).find(1)
    end
  end
end




class LeftOuterJoinAssociationTest < ActiveRecord::TestCase
  # Uses || operator in SQL. Just trust core gets value out of this test.
  coerce_tests! :test_does_not_override_select
end




class NamedScopingTest < ActiveRecord::TestCase
  # This works now because we add an `order(:id)` sort to break the order tie for deterministic results.
  coerce_tests! :test_scopes_honor_current_scopes_from_when_defined
  def test_scopes_honor_current_scopes_from_when_defined_coerced
    assert !Post.ranked_by_comments.order(:id).limit_by(5).empty?
    assert !authors(:david).posts.ranked_by_comments.order(:id).limit_by(5).empty?
    assert_not_equal Post.ranked_by_comments.order(:id).limit_by(5), authors(:david).posts.ranked_by_comments.order(:id).limit_by(5)
    assert_not_equal Post.order(:id).top(5), authors(:david).posts.order(:id).top(5)
    # Oracle sometimes sorts differently if WHERE condition is changed
    assert_equal authors(:david).posts.ranked_by_comments.limit_by(5).to_a.sort_by(&:id), authors(:david).posts.top(5).to_a.sort_by(&:id)
    assert_equal Post.ranked_by_comments.limit_by(5), Post.top(5)
  end
end




require 'models/developer'
require 'models/computer'
class NestedRelationScopingTest < ActiveRecord::TestCase
  coerce_tests! :test_merge_options
  def test_merge_options_coerced
    Developer.where('salary = 80000').scoping do
      Developer.limit(10).scoping do
        devs = Developer.all
        sql = devs.to_sql
        assert_match '(salary = 80000)', sql
        assert_match 'FETCH NEXT 10 ROWS ONLY', sql
      end
    end
  end
end




require 'models/topic'
class PersistenceTest < ActiveRecord::TestCase
  # We can not UPDATE identity columns.
  coerce_tests! :test_update_columns_changing_id

  # Previous test required updating a identity column.
  coerce_tests! :test_update_all_doesnt_ignore_order
  def test_update_all_doesnt_ignore_order_coerced
    david, mary = authors(:david), authors(:mary)
    david.id.must_equal 1
    mary.id.must_equal 2
    david.name.wont_equal mary.name
    assert_sql(/UPDATE.*\(SELECT \[authors\].\[id\] FROM \[authors\].*ORDER BY \[authors\].\[id\]/i) do
      Author.where('[id] > 1').order(:id).update_all(name: 'Test')
    end
    david.reload.name.must_equal 'David'
    mary.reload.name.must_equal 'Test'
  end

  # We can not UPDATE identity columns.
  coerce_tests! :test_update_attributes
  def test_update_attributes_coerced
    topic = Topic.find(1)
    assert !topic.approved?
    assert_equal "The First Topic", topic.title
    topic.update_attributes("approved" => true, "title" => "The First Topic Updated")
    topic.reload
    assert topic.approved?
    assert_equal "The First Topic Updated", topic.title
    topic.update_attributes(approved: false, title: "The First Topic")
    topic.reload
    assert !topic.approved?
    assert_equal "The First Topic", topic.title
    # SQLServer: Here is where it breaks down. No exceptions.
    # assert_raise(ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid) do
    #   topic.update_attributes(id: 3, title: "Hm is it possible?")
    # end
    # assert_not_equal "Hm is it possible?", Topic.find(3).title
    # topic.update_attributes(id: 1234)
    # assert_nothing_raised { topic.reload }
    # assert_equal topic.title, Topic.find(1234).title
  end
end




require 'models/topic'
module ActiveRecord
  class PredicateBuilderTest < ActiveRecord::TestCase
    coerce_tests! :test_registering_new_handlers
    def test_registering_new_handlers_coerced
      Topic.predicate_builder.register_handler(Regexp, proc do |column, value|
        Arel::Nodes::InfixOperation.new('~', column, Arel.sql(value.source))
      end)
      assert_match %r{\[topics\].\[title\] ~ rails}i, Topic.where(title: /rails/).to_sql
    ensure
      Topic.reset_column_information
    end
  end
end




class PrimaryKeysTest < ActiveRecord::TestCase
  # Gonna trust Rails core for this. We end up with 2 querys vs 3 asserted
  # but as far as I can tell, this is only one for us anyway.
  coerce_tests! :test_create_without_primary_key_no_extra_query
end




require 'models/task'
class QueryCacheTest < ActiveRecord::TestCase
  coerce_tests! :test_cache_does_not_wrap_string_results_in_arrays
  def test_cache_does_not_wrap_string_results_in_arrays_coerced
    Task.cache do
      assert_kind_of Numeric, Task.connection.select_value("SELECT count(*) AS count_all FROM tasks")
    end
  end
end




require 'models/post'
class RelationTest < ActiveRecord::TestCase
  # Use LEN vs LENGTH function.
  coerce_tests! :test_reverse_order_with_function
  def test_reverse_order_with_function_coerced
    topics = Topic.order("LEN(title)").reverse_order
    assert_equal topics(:second).title, topics.first.title
  end

  # Use LEN vs LENGTH function.
  coerce_tests! :test_reverse_order_with_function_other_predicates
  def test_reverse_order_with_function_other_predicates_coerced
    topics = Topic.order("author_name, LEN(title), id").reverse_order
    assert_equal topics(:second).title, topics.first.title
    topics = Topic.order("LEN(author_name), id, LEN(title)").reverse_order
    assert_equal topics(:fifth).title, topics.first.title
  end

  # We have implicit ordering, via FETCH.
  coerce_tests! %r{doesn't have implicit ordering}

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

  # Use LEN() vs length() function.
  coerce_tests! :test_reverse_arel_assoc_order_with_function
  def test_reverse_arel_assoc_order_with_function_coerced
    topics = Topic.order(Arel.sql("LEN(title)") => :asc).reverse_order
    assert_equal topics(:second).title, topics.first.title
  end
end




require 'models/post'
class SanitizeTest < ActiveRecord::TestCase
  coerce_tests! :test_sanitize_sql_like_example_use_case
  def test_sanitize_sql_like_example_use_case_coerced
    searchable_post = Class.new(Post) do
      def self.search(term)
        where("title LIKE ?", sanitize_sql_like(term, '!'))
      end
    end
    assert_sql(/\(title LIKE N'20!% !_reduction!_!!'\)/) do
      searchable_post.search("20% _reduction_!").to_a
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




require 'models/topic'
class TransactionTest < ActiveRecord::TestCase
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




require 'models/tag'
class TransactionIsolationTest < ActiveRecord::TestCase
  # SQL Server will lock the table for counts even when both
  # connections are `READ COMMITTED`. So we bypass with `READPAST`.
  coerce_tests! %r{read committed}
  test "read committed coerced" do
    Tag.transaction(isolation: :read_committed) do
      assert_equal 0, Tag.count
      Tag2.transaction do
        Tag2.create
        assert_equal 0, Tag.lock('WITH(READPAST)').count
      end
    end
    assert_equal 1, Tag.count
  end

  # I really need some help understanding this one.
  coerce_tests! %r{repeatable read}
end




require 'models/book'
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
    assert_equal 'id', model.primary_key
  end
end
class ViewWithoutPrimaryKeyTest < ActiveRecord::TestCase
  # We have a few view tables. use includes vs equality.
  coerce_tests! :test_views
  def test_views_coerced
    assert_includes @connection.views, Paperback.table_name
  end
end




require 'models/author'
class YamlSerializationTest < ActiveRecord::TestCase
  coerce_tests! :test_types_of_virtual_columns_are_not_changed_on_round_trip
  def test_types_of_virtual_columns_are_not_changed_on_round_trip_coerced
    author = Author.select('authors.*, 5 as posts_count').first
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
end




class DefaultNumbersTest < ActiveRecord::TestCase
  # We do better with native types and do not return strings for everything.
  coerce_tests! :test_default_positive_integer
  def test_default_positive_integer_coerced
    record = DefaultNumber.new
    assert_equal 7, record.positive_integer
    assert_equal 7, record.positive_integer_before_type_cast
  end
  coerce_tests! :test_default_negative_integer
  def test_default_negative_integer_coerced
    record = DefaultNumber.new
    assert_equal -5, record.negative_integer
    assert_equal -5, record.negative_integer_before_type_cast
  end
end




module ActiveRecord
  class CollectionCacheKeyTest < ActiveRecord::TestCase
    # Will trust rails has this sorted since you cant offset without a limit.
    coerce_tests! %r{with offset which return 0 rows}
  end
end




module ActiveRecord
  class StatementCacheTest < ActiveRecord::TestCase
    # Getting random failures.
    coerce_tests! :test_find_does_not_use_statement_cache_if_table_name_is_changed
  end
end




module ActiveRecord
  module ConnectionAdapters
    class SchemaCacheTest < ActiveRecord::TestCase
      private
      # We need to give the full path for this to work.
      def schema_dump_path
        File.join ARTest::SQLServer.root_activerecord, 'test/assets/schema_dump_5_1.yml'
      end
    end
  end
end

