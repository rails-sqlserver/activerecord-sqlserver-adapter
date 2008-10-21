# The filename begins with "aaaa" to ensure this is the first test.
require 'cases/sqlserver_helper'

class AAAACreateTablesTestSqlserver < ActiveRecord::TestCase
  self.use_transactional_fixtures = false

  def setup
    @ar_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', '..', 'rails/activerecord/test/schema'))
    @base_path = "#{File.dirname(__FILE__)}/../fixtures/db_definitions"
  end

  def __test_sqlserver_load_test_schema
    execute_sql_file("#{@base_path}/sqlserver.drop.sql", ActiveRecord::Base.connection)
    execute_sql_file("#{@base_path}/sqlserver.sql", ActiveRecord::Base.connection)
    execute_sql_file("#{@base_path}/sqlserver2.drop.sql", Course.connection)
    execute_sql_file("#{@base_path}/sqlserver2.sql", Course.connection)
    assert true
  end

  def test_activerecord_load_test_schema
    eval(File.read("#{@ar_path}/schema.rb"))
    eval(File.read("#{@ar_path}/schema2.rb"))
    assert_equal ["courses"], Course.connection.tables, "Make sure schema2.rb creates table in Course.connection to arunit2."
  end

  private
  
    def execute_sql_file(path, connection)
      File.read(path).split(';').each_with_index do |sql, i|
        begin
          connection.execute("\n\n-- statement ##{i}\n#{sql}\n") unless sql.blank?
        rescue ActiveRecord::StatementInvalid
          #$stderr.puts "warning: #{$!}"
        end
      end
    end
end
