# frozen_string_literal: true

require "cases/helper_sqlserver"

class TemporaryTableSQLServer < ActiveRecord::TestCase
  def test_insert_into_temporary_table
    ActiveRecord::Base.with_connection do |conn|
      conn.exec_query("CREATE TABLE #temp_users (id INT IDENTITY(1,1), name NVARCHAR(100))")

      result = conn.exec_query("SELECT * FROM #temp_users")
      assert_equal 0, result.count

      conn.exec_query("INSERT INTO #temp_users (name) VALUES ('John'), ('Doe')")

      result = conn.exec_query("SELECT * FROM #temp_users")
      assert_equal 2, result.count
    end
  end
end
