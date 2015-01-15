require 'cases/helper_sqlserver'

class SpecificSchemaTestSQLServer < ActiveRecord::TestCase

  after { SSTestEdgeSchema.delete_all }

  it 'handle dollar symbols' do
    SSTestDollarTableName.new.save
    SSTestDollarTableName.limit(20).offset(1)
  end

  it 'be able to complex count tables with no primary key' do
    SSTestNoPkData.delete_all
    10.times { |n| SSTestNoPkData.create! name: "Test#{n}" }
    assert_equal 1, SSTestNoPkData.where(name: 'Test5').count
  end

  it 'quote table names properly even when they are views' do
    obj = SSTestQuotedTable.create!
    assert_nothing_raised { assert SSTestQuotedTable.first }
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

  # With uniqueidentifier column

  let(:newid) { ActiveRecord::Base.connection.newid_function }

  it 'returns a new id via connection newid_function' do
    assert_guid newid
  end

  it 'allow a simple insert and read of a column without a default function' do
    obj = SSTestEdgeSchema.create! guid: newid
    assert_equal newid, SSTestEdgeSchema.find(obj.id).guid
  end

  it 'record the default function name in the column definition but still show a nil real default, will use one day for insert/update' do
    newid_column = SSTestEdgeSchema.columns_hash['guid_newid']
    assert newid_column.default_function.present?
    assert_nil newid_column.default
    assert_equal 'newid()', newid_column.default_function
    newseqid_column = SSTestEdgeSchema.columns_hash['guid_newseqid']
    assert newseqid_column.default_function.present?
    assert_nil newseqid_column.default
    assert_equal 'newsequentialid()', newseqid_column.default_function
  end

  it 'use model callback to set get a new guid' do
    obj = SSTestEdgeSchema.new
    obj.new_id_setting = true
    obj.save!
    assert_guid obj.guid_newid
  end


  protected

  def assert_guid(guid)
    assert_match %r|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}|, guid
  end

end
