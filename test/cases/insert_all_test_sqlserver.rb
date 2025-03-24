# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/sqlserver/recurring_task"

class InsertAllTestSQLServer < ActiveRecord::TestCase
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
