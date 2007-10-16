# The filename begins with "aaaa" to ensure this is the first test.
require 'abstract_unit'

class AAAACreateTablesTestSqlserver < Test::Unit::TestCase
  self.use_transactional_fixtures = false

  def setup
    @ar_path = "../../../rails/activerecord/test/fixtures/db_definitions"
    @base_path = "#{File.dirname(__FILE__)}/fixtures/db_definitions"
  end

  def test_sqlserver_load_test_schema
    execute_sql_file("#{@base_path}/sqlserver.drop.sql", ActiveRecord::Base.connection)
    execute_sql_file("#{@base_path}/sqlserver.sql", ActiveRecord::Base.connection)
    execute_sql_file("#{@base_path}/sqlserver2.drop.sql", Course.connection)
    execute_sql_file("#{@base_path}/sqlserver2.sql", Course.connection)
    assert true
  end

  #FUTURE
  def __test_activerecord_load_test_schema
    #FUTURE: eval(File.read("#{@ar_path}/schema.rb"))
    eval(File.read("#{@base_path}/schema.rb"))
    connection = ActiveRecord::Base.connection
    begin
      ActiveRecord::Base.connection = Course.connection
      #FUTURE: eval(File.read("#{@ar_path}/schema2.rb"))
      eval(File.read("#{@base_path}/schema2.rb"))
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
# The filename begins with "aaaa" to ensure this is the first test.
require 'abstract_unit'

class AAAACreateTablesTestSqlserver < Test::Unit::TestCase
  self.use_transactional_fixtures = false

  def setup
    @ar_path = "../../../rails/activerecord/test/fixtures/db_definitions"
    @base_path = "#{File.dirname(__FILE__)}/fixtures/db_definitions"
  end

  def test_sqlserver_load_test_schema
    execute_sql_file("#{@base_path}/sqlserver.drop.sql", ActiveRecord::Base.connection)
    execute_sql_file("#{@base_path}/sqlserver.sql", ActiveRecord::Base.connection)
    execute_sql_file("#{@base_path}/sqlserver2.drop.sql", Course.connection)
    execute_sql_file("#{@base_path}/sqlserver2.sql", Course.connection)
    assert true
  end

  #FUTURE
  def __test_activerecord_load_test_schema
    #FUTURE: eval(File.read("#{@ar_path}/schema.rb"))
    eval(File.read("#{@base_path}/schema.rb"))
    connection = ActiveRecord::Base.connection
    begin
      ActiveRecord::Base.connection = Course.connection
      #FUTURE: eval(File.read("#{@ar_path}/schema2.rb"))
      eval(File.read("#{@base_path}/schema2.rb"))
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
