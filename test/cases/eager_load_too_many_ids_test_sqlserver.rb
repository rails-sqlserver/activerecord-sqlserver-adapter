require "cases/helper_sqlserver"
require "models/citation"
require "models/book"

class EagerLoadingTooManyIdsTest < ActiveRecord::TestCase
  fixtures :citations

  def test_batch_preloading_too_many_ids
    in_clause_length = 10_000

    # We Monkey patch Preloader to work with batches of 10_000 records.
    # Expect: N Books queries + Citation query
    expected_query_count = (Citation.count / in_clause_length.to_f).ceil + 1
    assert_queries(expected_query_count) do
      Citation.preload(:reference_of).to_a.size
    end
  end
end
