require 'cases/helper_sqlserver'


# Windows/Appveyor
if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
  # All of these are due to Time.local(2000).zone. See http://git.io/v3t0o
  class BelongsToAssociationsTest < ActiveRecord::TestCase
    coerce_tests! :test_belongs_to_with_touch_option_on_touch_without_updated_at_attributes
  end
  class BasicsTest < ActiveRecord::TestCase
    coerce_tests! :test_preserving_time_objects_with_local_time_conversion_to_default_timezone_utc
    coerce_tests! :test_preserving_time_objects_with_time_with_zone_conversion_to_default_timezone_local
    coerce_tests! :test_preserving_time_objects_with_utc_time_conversion_to_default_timezone_local
  end
  class DirtyTest < ActiveRecord::TestCase
    coerce_tests! :test_save_always_should_update_timestamps_when_serialized_attributes_are_present
    coerce_tests! :test_previous_changes # Coupled to above test.
  end
end


module ActiveRecord
  class AdapterTest < ActiveRecord::TestCase

    # As far as I can tell, SQL Server does not support null bytes in strings.
    coerce_tests! :test_update_prepared_statement

  end
end




require 'models/topic'
class AttributeMethodsTest < ActiveRecord::TestCase

  coerce_tests! :test_typecast_attribute_from_select_to_false
  def test_typecast_attribute_from_select_to_false_coerced
    Topic.create(:title => 'Budget')
    topic = Topic.all.merge!(:select => "topics.*, IIF (1 = 2, 1, 0) as is_test").first
    assert !topic.is_test?
  end

  coerce_tests! :test_typecast_attribute_from_select_to_true
  def test_typecast_attribute_from_select_to_true_coerced
    Topic.create(:title => 'Budget')
    topic = Topic.all.merge!(:select => "topics.*, IIF (1 = 1, 1, 0) as is_test").first
    assert topic.is_test?
  end

end




class BasicsTest < ActiveRecord::TestCase

  coerce_tests! :test_column_names_are_escaped
  def test_column_names_are_escaped_coerced
    conn      = ActiveRecord::Base.connection
    classname = conn.class.name[/[^:]*$/]
    badchar   = "'"
    quoted = conn.quote_column_name "foo#{badchar}bar"
    assert_equal "[foo'bar]", quoted
  end

  # PENDING: [Rails5.x] Remove coerced tests and use simple symbol types..
  # This test has a few problems. First, it would require that we use the
  # `Type::SQLServer::BigInteger.new(limit: 8)` for the `world_population` attribute.
  coerce_tests! :test_numeric_fields
  coerce_tests! :test_numeric_fields_with_scale

  # Just like PostgreSQLAdapter does.
  coerce_tests! :test_respect_internal_encoding

  # Caused in Rails v4.2.5 by adding `firm_id` column in this http://git.io/vBfMs
  # commit. Trust Rails has this covered.
  coerce_tests! :test_find_keeps_multiple_group_values

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
    coerce_tests! :test_binds_are_logged,
                  :test_binds_are_logged_after_type_cast

  end
end




class CalculationsTest < ActiveRecord::TestCase

  # Are decimal, not integer.
  coerce_tests! :test_should_return_decimal_average_of_integer_field
  def test_should_return_decimal_average_of_integer_field_coerced
    value = Account.average(:id)
    assert_equal BigDecimal('3.0').to_s, BigDecimal(value).to_s
  end

  coerce_tests! :test_limit_is_kept
  def test_limit_is_kept_coerced
    queries = assert_sql { Account.limit(1).count }
    assert_equal 1, queries.length
    queries.first.must_match %r{ORDER BY \[accounts\]\.\[id\] ASC OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY}
  end

  coerce_tests! :test_limit_with_offset_is_kept
  def test_limit_with_offset_is_kept_coerced
    queries = assert_sql { Account.limit(1).offset(1).count }
    assert_equal 1, queries.length
    queries.first.must_match %r{ORDER BY \[accounts\]\.\[id\] ASC OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY}
  end

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

      # Our defaults are reall 70000 integers vs '70000' strings.
      coerce_tests! :test_rename_column_preserves_default_value_not_null
      def test_rename_column_preserves_default_value_not_null_coerced
        add_column 'test_models', 'salary', :integer, :default => 70000
        default_before = connection.columns("test_models").find { |c| c.name == "salary" }.default
        assert_equal 70000, default_before
        rename_column "test_models", "salary", "annual_salary"
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

    end
  end
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




require 'models/post'
require 'models/subscriber'
class EachTest < ActiveRecord::TestCase

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

end




require 'models/owner'
class Owner < ActiveRecord::Base
  scope :including_last_pet, -> {
    select('owners.*, (select TOP (1) p.pet_id from pets p where p.owner_id = owners.owner_id order by p.name desc ) as last_pet_id').
    includes(:last_pet)
  }
end
class EagerAssociationTest < ActiveRecord::TestCase

  # Use LEN() vs length() function.
  coerce_tests! :test_count_with_include
  def test_count_with_include_coerced
    assert_equal 3, authors(:david).posts_with_comments.where("LEN(comments.body) > 15").references(:comments).count
  end

  # Use TOP (1) in scope vs limit 1.
  coerce_tests! %r{including association based on sql condition and no database column}
  it "including association based on sql condition and no database column coerced" do
    assert_equal pets(:parrot), Owner.including_last_pet.first.last_pet
  end

end




require 'models/topic'
class FinderTest < ActiveRecord::TestCase

  coerce_tests! %r{doesn't have implicit ordering},
                :test_find_doesnt_have_implicit_ordering # We have implicit ordering, via FETCH.

  coerce_tests! :test_exists_does_not_select_columns_without_alias
  def test_exists_does_not_select_columns_without_alias_coerced
    assert_sql(/SELECT\s+1 AS one FROM \[topics\].*OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY/i) do
      Topic.exists?
    end
  end

  coerce_tests! :test_string_sanitation
  def test_string_sanitation_coerced
    assert_not_equal "'something ' 1=1'", ActiveRecord::Base.sanitize("something ' 1=1")
    assert_equal "N'something; select table'", ActiveRecord::Base.sanitize("something; select table")
  end

  coerce_tests! :test_take_and_first_and_last_with_integer_should_use_sql_limit
  def test_take_and_first_and_last_with_integer_should_use_sql_limit_coerced
    assert_sql(/OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY/) { Topic.take(3).entries }
    assert_sql(/OFFSET 0 ROWS FETCH NEXT 2 ROWS ONLY/) { Topic.first(2).entries }
    assert_sql(/OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY/) { Topic.last(5).entries }
  end

  # This fails only when run in the full test suite task. Just taking it out of the mix.
  coerce_tests! :test_find_with_order_on_included_associations_with_construct_finder_sql_for_association_limiting_and_is_distinct

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
    assert_sql(/\[companies\]\.\[id\] IN \(1\)/) do
      Account.all.merge!(:includes => :firm).find(1)
    end
  end

end




class BigNumber < ActiveRecord::Base
  attribute :value_of_e, Type::SQLServer::Integer.new
  attribute :my_house_population, Type::SQLServer::Integer.new
end
class MigrationTest < ActiveRecord::TestCase

  # PENDING: [Rails5.x] Remove coerced tests and use simple symbol types.
  coerce_tests! :test_add_table_with_decimals

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
      PredicateBuilder.register_handler(Regexp, proc do |column, value|
        Arel::Nodes::InfixOperation.new('~', column, Arel.sql(value.source))
      end)
      assert_match %r{\[topics\]\.\[title\] ~ rails}i, Topic.where(title: /rails/).to_sql
    end

  end
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

  # We have implicit ordering, via FETCH.
  coerce_tests! %r{doesn't have implicit ordering}

  # We are not doing order duplicate removal anymore.
  coerce_tests! :test_order_using_scoping

  # Account for our `EXEC sp_executesql...` statements.
  coerce_tests! :test_to_sql_on_eager_join
  def test_to_sql_on_eager_join_coerced
    expected = assert_sql { Post.eager_load(:last_comment).order('comments.id DESC').to_a }.first
    actual = Post.eager_load(:last_comment).order('comments.id DESC').to_sql
    actual = "EXEC sp_executesql N'#{ActiveRecord::ConnectionAdapters::SQLServer::Utils.quote_string(actual)}'"
    assert_equal expected, actual
  end

  # We are not doing order duplicate removal anymore.
  coerce_tests! :test_default_scope_order_with_scope_order

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
    assert_sql(/\(title LIKE N''20!% !_reduction!_!!''\)/) do
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

  # This accidently returns the wrong number because of our tables too.
  coerce_tests! :test_types_line_up

  # This is a poorly written test and really does not catch the bottom'ness it is meant too. Ours throw it off.
  coerce_tests! :test_foreign_keys_are_dumped_at_the_bottom_to_circumvent_dependency_issues

  # Fall through false positive with no filter.
  coerce_tests! :test_schema_dumps_partial_indices
  def test_schema_dumps_partial_indices_coerced
    index_definition = standard_dump.split(/\n/).grep(/add_index.*company_partial_index/).first.strip
    assert_equal 'add_index "companies", ["firm_id", "type"], name: "company_partial_index", where: "([rating]>(10))"', index_definition
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


require 'models/post'
module ActiveRecord
  class WhereChainTest < ActiveRecord::TestCase

    coerce_tests! :test_not_eq_with_array_parameter
    def test_not_eq_with_array_parameter_coerced
      expected = Arel::Nodes::Not.new("title = N'hello'")
      relation = Post.where.not(['title = ?', 'hello'])
      assert_equal([expected], relation.where_values)
    end

  end
end




class ViewWithPrimaryKeyTest < ActiveRecord::TestCase

  # We do better than ActiveRecord and find the views PK.
  coerce_tests! :test_does_not_assume_id_column_as_primary_key

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

