require 'cases/sqlserver_helper'

class ExecuteProcedureTestSqlserver < ActiveRecord::TestCase

  setup do
    @klass = ActiveRecord::Base
  end

  should 'execute a simple procedure' do
    tables = @klass.execute_procedure :sp_tables
    assert_instance_of Array, tables
    assert tables.first.respond_to?(:keys)
  end

  should 'take parameter arguments' do
    tables = @klass.execute_procedure :sp_tables, 'sql_server_chronics'
    table_info = tables.first
    assert_equal 1, tables.size
    assert_equal (ENV['ARUNIT_DB_NAME'] || 'activerecord_unittest'), table_info['TABLE_QUALIFIER'], "Table Info: #{table_info.inspect}"
    assert_equal 'TABLE', table_info['TABLE_TYPE'], "Table Info: #{table_info.inspect}"
  end

  should 'allow multiple result sets to be returned' do
    results1, results2 = @klass.execute_procedure('sp_helpconstraint','accounts')
    assert_instance_of Array, results1
    assert results1.first.respond_to?(:keys)
    assert results1.first['Object Name']
    assert_instance_of Array, results2
    assert results2.first.respond_to?(:keys)
    assert results2.first['constraint_name']
    assert results2.first['constraint_type']
  end

  should 'take named parameter arguments' do
    tables = @klass.execute_procedure :sp_tables, table_name: 'tables', table_owner: 'sys'
    table_info = tables.first
    assert_equal 1, tables.size
    assert_equal (ENV['ARUNIT_DB_NAME'] || 'activerecord_unittest'), table_info['TABLE_QUALIFIER'], "Table Info: #{table_info.inspect}"
    assert_equal 'VIEW', table_info['TABLE_TYPE'], "Table Info: #{table_info.inspect}"
  end


end
