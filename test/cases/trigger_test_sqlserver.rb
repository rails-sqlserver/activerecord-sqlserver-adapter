# encoding: UTF-8
require 'cases/helper_sqlserver'

class SQLServerTriggerTest < ActiveRecord::TestCase
  after  { exclude_output_inserted_table_names.clear }

  let(:exclude_output_inserted_table_names) do
    ActiveRecord::ConnectionAdapters::SQLServerAdapter.exclude_output_inserted_table_names
  end

  it 'can insert into a table with output inserted - with a true setting for table name' do
    exclude_output_inserted_table_names['sst_table_with_trigger'] = true
    assert SSTestTriggerHistory.all.empty?
    obj = SSTestTrigger.create! event_name: 'test trigger'
    ['Fixnum', 'Integer'].must_include obj.id.class.name
    obj.event_name.must_equal 'test trigger'
    obj.id.must_be :present?
    obj.id.to_s.must_equal SSTestTriggerHistory.first.id_source
  end

  it 'can insert into a table with output inserted - with a uniqueidentifier value' do
    exclude_output_inserted_table_names['sst_table_with_uuid_trigger'] = 'uniqueidentifier'
    assert SSTestTriggerHistory.all.empty?
    obj = SSTestTriggerUuid.create! event_name: 'test uuid trigger'
    obj.id.class.name.must_equal 'String'
    obj.event_name.must_equal 'test uuid trigger'
    obj.id.must_be :present?
    obj.id.to_s.must_equal SSTestTriggerHistory.first.id_source
  end
end
