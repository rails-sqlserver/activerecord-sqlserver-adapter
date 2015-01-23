require 'cases/helper_sqlserver'


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



require 'models/author'
class YamlSerializationTest < ActiveRecord::TestCase

  fixtures :authors

  coerce_tests! :test_types_of_virtual_columns_are_not_changed_on_round_trip
  def test_types_of_virtual_columns_are_not_changed_on_round_trip_coerced
    author = Author.select('authors.*, 5 as posts_count').first
    dumped = YAML.load(YAML.dump(author))
    assert_equal 5, author.posts_count
    assert_equal 5, dumped.posts_count
  end

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



require 'models/company'
class InheritanceTest < ActiveRecord::TestCase

  fixtures :companies, :projects, :subscribers, :accounts, :vegetables

  coerce_tests! :test_eager_load_belongs_to_primary_key_quoting
  def test_eager_load_belongs_to_primary_key_quoting_coerced
    con = Account.connection
    assert_sql(/\[companies\]\.\[id\] IN \(1\)/) do
      Account.all.merge!(:includes => :firm).find(1)
    end
  end

end



require 'models/developer'
require 'models/computer'
class NestedRelationScopingTest < ActiveRecord::TestCase

  fixtures :authors, :developers, :projects, :comments, :posts

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



require 'models/post'
require 'models/subscriber'
class EachTest < ActiveRecord::TestCase

  fixtures :posts, :subscribers

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



module ActiveRecord
  class Migration
    class ChangeSchemaTest < ActiveRecord::TestCase

      coerce_tests! :test_create_table_with_bigint,
                    :test_create_table_with_defaults # We test these.

    end
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

end



class RelationTest < ActiveRecord::TestCase

  coerce_tests! %r{doesn't have implicit ordering} # We have implicit ordering, via FETCH.

end

