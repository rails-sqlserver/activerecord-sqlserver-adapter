# frozen_string_literal: true

require "cases/helper_sqlserver"

class TemporaryTableSQLServer < ActiveRecord::TestCase
  # setup do
  #   @connection = ActiveRecord::Base.lease_connection
  #   @connection.create_table(:barcodes, primary_key: "code", id: :uuid, force: true)
  # end
  #
  # # teardown do
  # #   @connection.drop_table(:barcodes, if_exists: true)
  # # end
  #
  def test_insert_into_temporary_table
    ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, payload|
      puts payload[:sql]
    end


    ActiveRecord::Base.with_connection do |conn|
      temp_table = "#temp_users"
      # connection.exec_query("IF OBJECT_ID('tempdb..#{temp_table}') IS NOT NULL DROP TABLE #{temp_table}")

      puts "Creating table"
      conn.exec_query("CREATE TABLE #{temp_table} (id INT IDENTITY(1,1), name NVARCHAR(100))")

      puts "Selecting table"
      result = conn.exec_query("SELECT * FROM #{temp_table}")
      puts "Result: #{result.to_a}"

      puts "Inserting into table"

      # ❌ This raises "Table doesn’t exist" error
      conn.exec_query("INSERT INTO #{temp_table} (name) VALUES ('John')")



      # ✅ Workaround: Only runs if the table still exists in this session
      # conn.exec_query("IF OBJECT_ID('tempdb..#{temp_table}') IS NOT NULL INSERT INTO #{temp_table} (name) VALUES ('John')")

      # ✅ Workaround: raw_connection works without issue
      # conn.raw_connection.execute("IF OBJECT_ID('tempdb..#{temp_table}') IS NOT NULL INSERT INTO #{temp_table} (name) VALUES ('John')")

      puts "Selecting table again"
      result = conn.exec_query("SELECT * FROM #{temp_table}")
      puts "Result: #{result.to_a}"
    end
  end
end
