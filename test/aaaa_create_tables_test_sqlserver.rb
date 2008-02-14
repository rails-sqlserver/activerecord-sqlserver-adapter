# The filename begins with "aaaa" to ensure this is the first test.
require 'cases/helper'

class AAAACreateTablesTestSqlserver < ActiveRecord::TestCase
  self.use_transactional_fixtures = false

  def setup
    @ar_path = "../../../rails/activerecord/test/schema"
    @base_path = "#{File.dirname(__FILE__)}/fixtures/db_definitions"
  end

  def test_sqlserver_load_test_schema
    execute_sql_file("#{@base_path}/sqlserver.drop.sql", ActiveRecord::Base.connection)
    execute_sql_file("#{@base_path}/sqlserver.sql", ActiveRecord::Base.connection)
    execute_sql_file("#{@base_path}/sqlserver2.drop.sql", Course.connection)
    execute_sql_file("#{@base_path}/sqlserver2.sql", Course.connection)
    assert true
  end

  def __test_activerecord_load_test_schema
    eval(File.read("#{@ar_path}/schema.rb"))
    connection = ActiveRecord::Base.connection
    begin
      ActiveRecord::Base.connection = Course.connection
      eval(File.read("#{@ar_path}/schema2.rb"))
    ensure
      ActiveRecord::Base.connection = connection
    end
    assert true
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
