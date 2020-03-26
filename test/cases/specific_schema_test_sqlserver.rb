require 'cases/helper_sqlserver'

class SpecificSchemaTestSQLServer < ActiveRecord::TestCase

  after { SSTestEdgeSchema.delete_all }

  it 'handle dollar symbols' do
    SSTestDollarTableName.create!
    SSTestDollarTableName.limit(20).offset(1)
  end

  it 'models can use tinyint pk tables' do
    obj = SSTestTinyintPk.create! name: '1'
    _(['Fixnum', 'Integer']).must_include obj.id.class.name
    _(SSTestTinyintPk.find(obj.id)).must_equal obj
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
    assert_nil default.string_with_null_default
    assert_equal 'null', default.string_with_pretend_null_one
    assert_equal '(null)', default.string_with_pretend_null_two
    assert_equal 'NULL', default.string_with_pretend_null_three
    assert_equal '(NULL)', default.string_with_pretend_null_four
    assert_equal '(3)', default.string_with_pretend_paren_three
  end

  it 'default strings after save' do
    default = SSTestStringDefault.create
    assert_nil default.string_with_null_default
    assert_equal 'null', default.string_with_pretend_null_one
    assert_equal '(null)', default.string_with_pretend_null_two
    assert_equal 'NULL', default.string_with_pretend_null_three
    assert_equal '(NULL)', default.string_with_pretend_null_four
  end

  it 'default objects work' do
    obj = SSTestObjectDefault.create! name: 'MetaSkills'
    _(obj.date).must_be_nil 'since this is set on insert'
    _(obj.reload.date).must_be_instance_of Date
  end

  it 'allows datetime2 as timestamps' do
    _(SSTestBooking.columns_hash['created_at'].sql_type).must_equal 'datetime2(7)'
    _(SSTestBooking.columns_hash['updated_at'].sql_type).must_equal 'datetime2(7)'
    obj1 = SSTestBooking.new name: 'test1'
    obj1.save!
    _(obj1.created_at).must_be_instance_of Time
    _(obj1.updated_at).must_be_instance_of Time
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
    sql = /ORDER BY \[sst_natural_pk_data\]\.\[legacy_id\] ASC OFFSET @0 ROWS FETCH NEXT @1 ROWS ONLY/
    assert_sql(sql) { SSTestNaturalPkData.limit(5).offset(5).load }
  end

  # Special quoted column

  it 'work as normal' do
    SSTestEdgeSchema.delete_all
    r = SSTestEdgeSchema.create! 'crazy]]quote' => 'crazyqoute'
    assert SSTestEdgeSchema.columns_hash['crazy]]quote']
    assert_equal r, SSTestEdgeSchema.where('crazy]]quote' => 'crazyqoute').first
  end

  it 'various methods to bypass national quoted columns for any column, but primarily useful for char/varchar' do
    value = Class.new do
      def quoted_id
        "'T'"
      end
    end
    # Using ActiveRecord's quoted_id feature for objects.
    assert_sql(/@0 = 'T'/) { SSTestDatatypeMigration.where(char_col: value.new).first }
    assert_sql(/@0 = 'T'/) { SSTestDatatypeMigration.where(varchar_col: value.new).first }
    # Using our custom char type data.
    type = ActiveRecord::Type::SQLServer::Char
    data = ActiveRecord::Type::SQLServer::Data
    assert_sql(/@0 = 'T'/) { SSTestDatatypeMigration.where(char_col: data.new('T', type.new)).first }
    assert_sql(/@0 = 'T'/) { SSTestDatatypeMigration.where(varchar_col: data.new('T', type.new)).first }
    # Taking care of everything.
    assert_sql(/@0 = 'T'/) { SSTestDatatypeMigration.where(char_col: 'T').first }
    assert_sql(/@0 = 'T'/) { SSTestDatatypeMigration.where(varchar_col: 'T').first }
  end

  it 'can update and hence properly quoted non-national char/varchar columns' do
    o = SSTestDatatypeMigration.create!
    o.varchar_col = "O'Reilly"
    o.save!
    _(o.reload.varchar_col).must_equal "O'Reilly"
    o.varchar_col = nil
    o.save!
    _(o.reload.varchar_col).must_be_nil
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
    _(db_uuid).must_match(acceptable_uuid)
  end

  # with similar table definition in two schemas

  it 'returns the correct primary columns' do
    connection = ActiveRecord::Base.connection
    assert_equal 'field_1', connection.columns('test.sst_schema_test_mulitple_schema').detect(&:is_primary?).name
    assert_equal 'field_2', connection.columns('test2.sst_schema_test_mulitple_schema').detect(&:is_primary?).name
  end

end
