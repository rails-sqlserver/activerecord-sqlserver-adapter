require 'cases/sqlserver_helper'
require 'models_sqlserver/no_pk_data'
require 'models_sqlserver/sql_server_dollar_table_name'
require 'models_sqlserver/sql_server_edge_schema'
require 'models_sqlserver/sql_server_natural_pk_int_data'
require 'models_sqlserver/sql_server_quoted_table'
require 'models_sqlserver/sql_server_quoted_view_1'
require 'models_sqlserver/sql_server_quoted_view_2'
require 'models_sqlserver/sql_server_tinyint_pk'
require 'models_sqlserver/string_default'
class SpecificSchemaTestSqlserver < ActiveRecord::TestCase

  should 'be able to complex count tables with no primary key' do
    NoPkData.delete_all
    10.times { |n| NoPkData.create! name: "Test#{n}" }
    assert_equal 1, NoPkData.where(name: 'Test5').count
  end

  should 'quote table names properly even when they are views' do
    obj = SqlServerQuotedTable.create!
    assert_nothing_raised { SqlServerQuotedTable.first }
    obj = SqlServerQuotedView1.create!
    assert_nothing_raised { SqlServerQuotedView1.first }
    obj = SqlServerQuotedView2.create!
    assert_nothing_raised { SqlServerQuotedView2.first }
  end

  should 'cope with multi line defaults' do
    default = StringDefault.new
    assert_equal "Some long default with a\nnew line.", default.string_with_multiline_default
  end

  should 'default strings before save' do
    default = StringDefault.new
    assert_equal nil, default.string_with_null_default
    assert_equal 'null', default.string_with_pretend_null_one
    assert_equal '(null)', default.string_with_pretend_null_two
    assert_equal 'NULL', default.string_with_pretend_null_three
    assert_equal '(NULL)', default.string_with_pretend_null_four
    assert_equal '(3)', default.string_with_pretend_paren_three
  end

  should 'default strings after save' do
    default = StringDefault.create
    assert_equal nil, default.string_with_null_default
    assert_equal 'null', default.string_with_pretend_null_one
    assert_equal '(null)', default.string_with_pretend_null_two
    assert_equal 'NULL', default.string_with_pretend_null_three
    assert_equal '(NULL)', default.string_with_pretend_null_four
  end

  context 'Testing edge case schemas' do

    setup do
      @edge_class = SqlServerEdgeSchema
    end

    context 'with tinyint primary key' do

      should 'work with identity inserts and finders' do
        record = SqlServerTinyintPk.new name: '1'
        record.id = 1
        record.save!
        assert_equal record, SqlServerTinyintPk.find(1)
      end

    end

    context 'with natural primary keys' do

      should 'work with identity inserts' do
        record = SqlServerNaturalPkData.new name: 'Test', description: 'Natural identity inserts.'
        record.id = '12345ABCDE'
        assert record.save
        assert_equal '12345ABCDE', record.reload.id
      end

      should 'work with identity inserts when the key is an int' do
        record = SqlServerNaturalPkIntData.new name: 'Test', description: 'Natural identity inserts.'
        record.id = 12
        assert record.save
        assert_equal 12, record.reload.id
      end

      should 'use primary key for row table order in pagination sql' do
    sql = /OVER \(ORDER BY \[natural_pk_data\]\.\[legacy_id\] ASC\)/
        assert_sql(sql) { SqlServerNaturalPkData.limit(5).offset(5).load }
      end

    end

    context 'with special quoted column' do

      should 'work as normal' do
        @edge_class.delete_all
        r = @edge_class.create! 'crazy]]quote' => 'crazyqoute'
        assert @edge_class.columns_hash['crazy]]quote']
        assert_equal r, @edge_class.where('crazy]]quote' => 'crazyqoute').first
      end

    end

    context 'with column names that have spaces' do

      should 'create record using a custom attribute reader and be able to load it back in' do
        value = 'Saved value into a column that has a space in the name.'
        record = @edge_class.create! with_spaces: value
        assert_equal value, @edge_class.find(record.id).with_spaces
      end

    end

    context 'with description column' do

      setup do
        @da = @edge_class.create! description: 'A'
        @db = @edge_class.create! description: 'B'
        @dc = @edge_class.create! description: 'C'
      end

      teardown { @edge_class.delete_all }

      should 'allow all sorts of ordering without adapter munging it up' do
        assert_equal ['A','B','C'], @edge_class.order('description').map(&:description)
        assert_equal ['A','B','C'], @edge_class.order('description asc').map(&:description)
        assert_equal ['A','B','C'], @edge_class.order('description ASC').map(&:description)
        assert_equal ['C','B','A'], @edge_class.order('description desc').map(&:description)
        assert_equal ['C','B','A'], @edge_class.order('description DESC').map(&:description)
      end

    end

    context 'with bigint column' do

      setup do
        @b5k   = 5000
        @bi5k  = @edge_class.create! bigint: @b5k, description: 'Five Thousand'
        @bnum  = 9_000_000_000_000_000_000
        @bimjr = @edge_class.create! bigint: @bnum, description: 'Close to max bignum'
      end

      should 'can find by biginit' do
        assert_equal @bi5k,  @edge_class.find_by_bigint(@b5k)
        assert_equal @b5k,   @edge_class.select('bigint').where(bigint: @b5k).first.bigint
        assert_equal @bimjr, @edge_class.find_by_bigint(@bnum)
        assert_equal @bnum,  @edge_class.select('bigint').where(bigint: @bnum).first.bigint
      end

    end

    context 'with tinyint column' do

      setup do
        @tiny1 = @edge_class.create! tinyint: 1
        @tiny255 = @edge_class.create! tinyint: 255
      end

      should 'not treat tinyint like boolean as mysql does' do
        assert_equal 1, @edge_class.find_by_tinyint(1).tinyint
        assert_equal 255, @edge_class.find_by_tinyint(255).tinyint
      end

      should 'throw an error when going out of our tiny int bounds' do
        assert_raise(ActiveRecord::StatementInvalid) { @edge_class.create! tinyint: 256 }
      end

    end

    context 'with uniqueidentifier column' do

      setup do
        @newid = ActiveRecord::Base.connection.newid_function
        assert_guid @newid
      end

      should 'allow a simple insert and read of a column without a default function' do
        obj = @edge_class.create! guid: @newid
        assert_equal @newid, @edge_class.find(obj.id).guid
      end

      should 'record the default function name in the column definition but still show a nil real default, will use one day for insert/update' do
        newid_column = @edge_class.columns_hash['guid_newid']
        assert newid_column.default_function.present?
        assert_nil newid_column.default
        assert_equal 'newid()', newid_column.default_function
        newseqid_column = @edge_class.columns_hash['guid_newseqid']
        assert newseqid_column.default_function.present?
        assert_nil newseqid_column.default
        assert_equal 'newsequentialid()', newseqid_column.default_function
      end

      should 'use model callback to set get a new guid' do
        obj = @edge_class.new
        obj.new_id_setting = true
        obj.save!
        assert_guid obj.guid_newid
      end

    end

    context 'with strange table names' do

      should 'handle dollar symbols' do
        SqlServerDollarTableName.new.save
        SqlServerDollarTableName.limit(20).offset(1)
      end

    end

  end


  protected

  def assert_guid(guid)
    assert_match %r|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}|, guid
  end

end
