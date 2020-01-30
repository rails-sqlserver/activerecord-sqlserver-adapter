# encoding: UTF-8
require 'cases/helper_sqlserver'

class SQLServerUuidTest < ActiveRecord::TestCase

  let(:acceptable_uuid) { ActiveRecord::ConnectionAdapters::SQLServer::Type::Uuid::ACCEPTABLE_UUID }

  it 'has a uuid primary key' do
    _(SSTestUuid.columns_hash['id'].type).must_equal :uuid
    assert SSTestUuid.primary_key
  end

  it 'can create with a new pk' do
    obj = SSTestUuid.create!
    _(obj.id).must_be :present?
    _(obj.id).must_match acceptable_uuid
  end

  it 'can create other uuid column on reload' do
    obj = SSTestUuid.create!
    obj.reload
    _(obj.other_uuid).must_match acceptable_uuid
  end

  it 'can find uuid pk via connection' do
    _(connection.primary_key(SSTestUuid.table_name)).must_equal 'id'
  end

  it 'changing column default' do
    table_name = SSTestUuid.table_name
    connection.add_column table_name, :thingy, :uuid, null: false, default: "NEWSEQUENTIALID()"
    SSTestUuid.reset_column_information
    column = SSTestUuid.columns_hash['thingy']
    _(column.default_function).must_equal "newsequentialid()"
    # Now to a different function.
    connection.change_column table_name, :thingy, :uuid, null: false, default: "NEWID()"
    SSTestUuid.reset_column_information
    column = SSTestUuid.columns_hash['thingy']
    _(column.default_function).must_equal "newid()"
  end

  it 'can insert even when use_output_inserted to false ' do
    obj = with_use_output_inserted_disabled { SSTestUuid.create!(name: "😢") }
    _(obj.id).must_be :nil?
  end

end
