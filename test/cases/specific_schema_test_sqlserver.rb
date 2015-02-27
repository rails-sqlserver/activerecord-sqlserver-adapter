require 'cases/helper_sqlserver'

class SpecificSchemaTestSQLServer < ActiveRecord::TestCase

  after { SSTestEdgeSchema.delete_all }

  it 'handle dollar symbols' do
    SSTestDollarTableName.create!
    SSTestDollarTableName.limit(20).offset(1)
  end

  it 'handle dot table names' do
    SSTestDotTableName.create! name: 'test'
    SSTestDotTableName.limit(20).offset(1)
    SSTestDotTableName.where(name: 'test').first.must_be :present?
  end

  it 'models can use tinyint pk tables' do
    obj = SSTestTinyintPk.create! name: '1'
    obj.id.is_a? Fixnum
    SSTestTinyintPk.find(obj.id).must_equal obj
  end

  it 'be able to complex count tables with no primary key' do
    SSTestNoPkData.delete_all
    10.times { |n| SSTestNoPkData.create! name: "Test#{n}" }
    assert_equal 1, SSTestNoPkData.where(name: 'Test5').count
  end

  it 'quote table names properly even when they are views' do
    obj = SSTestQuotedTable.create!
    assert_nothing_raised { assert SSTestQuotedTable.first }
    obj = SSTestQuotedTableUser.create!
    assert_nothing_raised { assert SSTestQuotedTableUser.first }
    obj = SSTestQuotedView1.create!
    assert_nothing_raised { assert SSTestQuotedView1.first }
    obj = SSTestQuotedView2.create!
    assert_nothing_raised { assert SSTestQuotedView2.first }
  end

  it 'cope with multi line defaults' do
    default = SSTestStringDefault.new
    assert_equal "Some long default with a\nnew line.", default.string_with_multiline_default
  end

  it 'default strings before save' do
    default = SSTestStringDefault.new
    assert_equal nil, default.string_with_null_default
    assert_equal 'null', default.string_with_pretend_null_one
    assert_equal '(null)', default.string_with_pretend_null_two
    assert_equal 'NULL', default.string_with_pretend_null_three
    assert_equal '(NULL)', default.string_with_pretend_null_four
    assert_equal '(3)', default.string_with_pretend_paren_three
  end

  it 'default strings after save' do
    default = SSTestStringDefault.create
    assert_equal nil, default.string_with_null_default
    assert_equal 'null', default.string_with_pretend_null_one
    assert_equal '(null)', default.string_with_pretend_null_two
    assert_equal 'NULL', default.string_with_pretend_null_three
    assert_equal '(NULL)', default.string_with_pretend_null_four
  end

  # Natural primary keys.

  it 'work with identity inserts' do
    record = SSTestNaturalPkData.new name: 'Test', description: 'Natural identity inserts.'
    record.id = '12345ABCDE'
    assert record.save
    assert_equal '12345ABCDE', record.reload.id
  end

  it 'work with identity inserts when the key is an int' do
    record = SSTestNaturalPkIntData.new name: 'Test', description: 'Natural identity inserts.'
    record.id = 12
    assert record.save
    assert_equal 12, record.reload.id
  end

  it 'use primary key for row table order in pagination sql' do
    sql = /ORDER BY \[sst_natural_pk_data\]\.\[legacy_id\] ASC OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY/
    assert_sql(sql) { SSTestNaturalPkData.limit(5).offset(5).load }
  end

  # Special quoted column

  it 'work as normal' do
    SSTestEdgeSchema.delete_all
    r = SSTestEdgeSchema.create! 'crazy]]quote' => 'crazyqoute'
    assert SSTestEdgeSchema.columns_hash['crazy]]quote']
    assert_equal r, SSTestEdgeSchema.where('crazy]]quote' => 'crazyqoute').first
  end

  # With column names that have spaces

  it 'create record using a custom attribute reader and be able to load it back in' do
    value = 'Saved value into a column that has a space in the name.'
    record = SSTestEdgeSchema.create! with_spaces: value
    assert_equal value, SSTestEdgeSchema.find(record.id).with_spaces
  end

  # With description column

  it 'allow all sorts of ordering without adapter munging it up with special description column' do
    SSTestEdgeSchema.create! description: 'A'
    SSTestEdgeSchema.create! description: 'B'
    SSTestEdgeSchema.create! description: 'C'
    assert_equal ['A','B','C'], SSTestEdgeSchema.order('description').map(&:description)
    assert_equal ['A','B','C'], SSTestEdgeSchema.order('description asc').map(&:description)
    assert_equal ['A','B','C'], SSTestEdgeSchema.order('description ASC').map(&:description)
    assert_equal ['C','B','A'], SSTestEdgeSchema.order('description desc').map(&:description)
    assert_equal ['C','B','A'], SSTestEdgeSchema.order('description DESC').map(&:description)
  end

  # For uniqueidentifier model helpers

  it 'returns a new id via connection newid_function' do
    acceptable_uuid = ActiveRecord::ConnectionAdapters::SQLServer::Type::Uuid::ACCEPTABLE_UUID
    db_uuid = ActiveRecord::Base.connection.newid_function
    db_uuid.must_match(acceptable_uuid)
  end

end
