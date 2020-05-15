# frozen_string_literal: true

if ENV["IN_MEMORY_OLTP"]
  require "config"
  require "active_record"
  require "support/config"
  require "support/connection"

  ARTest.connect

  if ActiveRecord::Base.connection.supports_in_memory_oltp?
    puts "Configuring In-Memory OLTP..."
    inmem_file = ARTest::SQLServer.test_root_sqlserver, "schema", "enable-in-memory-oltp.sql"
    inmem_sql = File.read File.join(inmem_file)
    ActiveRecord::Base.connection.execute(inmem_sql)
  end
end
