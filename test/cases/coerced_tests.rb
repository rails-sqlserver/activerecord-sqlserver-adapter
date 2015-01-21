require 'cases/helper_sqlserver'


require 'models/post'
class SanitizeTest < ActiveRecord::TestCase

  coerce_tests :test_sanitize_sql_like_example_use_case

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

  coerce_tests :test_types_of_virtual_columns_are_not_changed_on_round_trip

  def test_types_of_virtual_columns_are_not_changed_on_round_trip_coerced
    author = Author.select('authors.*, 5 as posts_count').first
    dumped = YAML.load(YAML.dump(author))
    assert_equal 5, author.posts_count
    assert_equal 5, dumped.posts_count
  end

end


module ActiveRecord
  module ConnectionAdapters
    class TypeLookupTest < ActiveRecord::TestCase

      coerce_all_tests! # Just like PostgreSQLAdapter does.

    end
  end
end

