require 'cases/helper_sqlserver'
require 'models/binary'
require 'models/author'
require 'models/post'

class SanitizeTest < ActiveRecord::TestCase

  COERCED_TESTS = [:test_sanitize_sql_like_example_use_case]

  include ARTest::SQLServer::CoercedTest

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
