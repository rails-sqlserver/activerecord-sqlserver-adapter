require 'cases/sqlserver_helper'
require 'models/car'

class ShowplanTestSqlserver < ActiveRecord::TestCase
  
  fixtures :cars
  
  context 'Unprepare previously prepared SQL' do
    
    should 'from simple statement' do
      plan = Car.where(:id => 1).explain
      assert plan.starts_with?("EXPLAIN for: SELECT [cars].* FROM [cars] WHERE [cars].[id] = 1")
      assert plan.include?("Clustered Index Seek"), 'make sure we do not showplan the sp_executesql'
    end

    should 'from multiline statement' do
      plan = Car.where("\n id = 1 \n").explain
      assert plan.starts_with?("EXPLAIN for: SELECT [cars].* FROM [cars] WHERE (\n id = 1 \n)")
      assert plan.include?("Clustered Index Seek"), 'make sure we do not showplan the sp_executesql'
    end
    
    should 'from prepared statement' do
      plan = capture_logger do
        with_threshold(0) { Car.find(1) }
      end
      assert plan.include?('EXPLAIN for: SELECT TOP (1) [cars].* FROM [cars] WHERE [cars].[id] = @0 [["id", 1]]')
      assert plan.include?("Clustered Index Seek"), 'make sure we do not showplan the sp_executesql'
    end
    
    should 'from prepared statement ...' do
      plan = capture_logger do
        with_threshold(0) { Car.where(:name => ',').first }
      end
      assert plan.include?("SELECT TOP (1) [cars].* FROM [cars] WHERE [cars].[name] = N','")
      assert plan.include?("TOP EXPRESSION"), 'make sure we do not showplan the sp_executesql'
      assert plan.include?("Clustered Index Scan"), 'make sure we do not showplan the sp_executesql'
    end
    
  end
  
  context 'With SHOWPLAN_TEXT option' do
    
    should 'use simple table printer' do
      with_showplan_option('SHOWPLAN_TEXT') do
        plan = Car.where(:id => 1).explain
        assert plan.starts_with?("EXPLAIN for: SELECT [cars].* FROM [cars] WHERE [cars].[id] = 1") 
        assert plan.include?("Clustered Index Seek"), 'make sure we do not showplan the sp_executesql'
      end
    end
    
  end
  
  context 'With SHOWPLAN_XML option' do
    
    should 'show formatted xml' do
      with_showplan_option('SHOWPLAN_XML') do
        plan = Car.where(:id => 1).explain
        assert plan.include?('ShowPlanXML')
      end
    end
    
  end
  
  
  private
  
  def base
    ActiveRecord::Base
  end

  def connection
    base.connection
  end
  
  def with_showplan_option(option)
    old_option = ActiveRecord::ConnectionAdapters::SQLServerAdapter.showplan_option
    ActiveRecord::ConnectionAdapters::SQLServerAdapter.showplan_option = option
    yield
  ensure
    ActiveRecord::ConnectionAdapters::SQLServerAdapter.showplan_option = old_option
  end
  
  def with_threshold(threshold)
    current_threshold = base.auto_explain_threshold_in_seconds
    base.auto_explain_threshold_in_seconds = threshold
    yield
  ensure
    base.auto_explain_threshold_in_seconds = current_threshold
  end
  
  def capture_logger
    original_logger = base.logger
    log = StringIO.new
    base.logger = Logger.new(log)
    base.logger.level = Logger::WARN
    yield
    log.string
  ensure
    base.logger = original_logger
  end

  def capture_queries
    base.auto_explain_threshold_in_seconds = nil
    queries = Thread.current[:available_queries_for_explain] = []
    with_threshold(0) do
      yield
    end
    queries
  ensure
    Thread.current[:available_queries_for_explain] = nil
  end
  
  
end
