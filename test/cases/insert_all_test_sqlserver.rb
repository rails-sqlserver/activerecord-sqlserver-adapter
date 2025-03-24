# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/book"
require "models/sqlserver/recurring_task"

class InsertAllTestSQLServer < ActiveRecord::TestCase
  # Test ported from the Rails `main` branch that is not on the `8-0-stable` branch.
  def test_insert_all_only_applies_last_value_when_given_duplicate_identifiers
    skip unless supports_insert_on_duplicate_skip?

    Book.insert_all [
                      { id: 111, name: "expected_new_name" },
                      { id: 111, name: "unexpected_new_name" }
                    ]
    assert_equal "expected_new_name", Book.find(111).name
  end

  # Test ported from the Rails `main` branch that is not on the `8-0-stable` branch.
  def test_upsert_all_only_applies_last_value_when_given_duplicate_identifiers
    skip unless supports_insert_on_duplicate_update? && !current_adapter?(:PostgreSQLAdapter)

    Book.create!(id: 112, name: "original_name")

    Book.upsert_all [
                      { id: 112, name: "unexpected_new_name" },
                      { id: 112, name: "expected_new_name" }
                    ]
    assert_equal "expected_new_name", Book.find(112).name
  end

  test "upsert_all recording of timestamps works with mixed datatypes" do
    task = RecurringTask.create!(
      key: "abcdef",
      priority: 5
    )

    RecurringTask.upsert_all([{
                                id: task.id,
                                priority: nil
                              }])

    assert_not_equal task.updated_at, RecurringTask.find(task.id).updated_at
  end
end
