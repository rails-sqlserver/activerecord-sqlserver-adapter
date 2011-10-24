require 'cases/sqlserver_helper'

class SpecificSchemaTestSqlserver < ActiveRecord::TestCase
  
  should 'be able to complex count tables with no primary key' do
    NoPkData.delete_all
    10.times { |n| NoPkData.create! :name => "Test#{n}" }
    assert_equal 1, NoPkData.where(:name => 'Test5').count
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
    
    context 'with natural primary keys' do

      should 'work with identity inserts' do
        record = SqlServerNaturalPkData.new :name => 'Test', :description => 'Natural identity inserts.'
        record.id = '12345ABCDE'
        assert record.save
        assert_equal '12345ABCDE', record.reload.id
      end

    end
    
    context 'with special quoted column' do

      should 'work as normal' do
        @edge_class.delete_all
        r = @edge_class.create! 'crazy]]quote' => 'crazyqoute'
        assert @edge_class.columns_hash['crazy]]quote']
        assert_equal r, @edge_class.first(:conditions => {'crazy]]quote' => 'crazyqoute'})
      end

    end
    
    context 'with description column' do

      setup do
        @da = @edge_class.create! :description => 'A'
        @db = @edge_class.create! :description => 'B'
        @dc = @edge_class.create! :description => 'C'
      end
      
      teardown { @edge_class.delete_all }

      should 'allow all sorts of ordering without adapter munging it up' do
        assert_equal ['A','B','C'], @edge_class.all(:order => 'description').map(&:description)
        assert_equal ['A','B','C'], @edge_class.all(:order => 'description asc').map(&:description)
        assert_equal ['A','B','C'], @edge_class.all(:order => 'description ASC').map(&:description)
        assert_equal ['C','B','A'], @edge_class.all(:order => 'description desc').map(&:description)
        assert_equal ['C','B','A'], @edge_class.all(:order => 'description DESC').map(&:description)
      end

    end
    
    context 'with bigint column' do

      setup do
        @b5k   = 5000
        @bi5k  = @edge_class.create! :bigint => @b5k, :description => 'Five Thousand'
        @bnum  = 9_000_000_000_000_000_000
        @bimjr = @edge_class.create! :bigint => @bnum, :description => 'Close to max bignum'
      end

      should 'can find by biginit' do
        assert_equal @bi5k,  @edge_class.find_by_bigint(@b5k)
        assert_equal @b5k,   @edge_class.find(:first, :select => 'bigint', :conditions => {:bigint => @b5k}).bigint
        assert_equal @bimjr, @edge_class.find_by_bigint(@bnum)
        assert_equal @bnum,  @edge_class.find(:first, :select => 'bigint', :conditions => {:bigint => @bnum}).bigint
      end

    end
    
    context 'with tinyint column' do

      setup do
        @tiny1 = @edge_class.create! :tinyint => 1
        @tiny255 = @edge_class.create! :tinyint => 255
      end

      should 'not treat tinyint like boolean as mysql does' do
        assert_equal 1, @edge_class.find_by_tinyint(1).tinyint
        assert_equal 255, @edge_class.find_by_tinyint(255).tinyint
      end
      
      should 'throw an error when going out of our tiny int bounds' do
        assert_raise(ActiveRecord::StatementInvalid) { @edge_class.create! :tinyint => 256 }
      end
      
    end
    
    context 'with uniqueidentifier column' do

      setup do
        @newid = ActiveRecord::Base.connection.newid_function
        assert_guid @newid
      end

      should 'allow a simple insert and read of a column without a default function' do
        obj = @edge_class.create! :guid => @newid
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
    
  end
  
  
  protected
  
  def assert_guid(guid)
    assert_match %r|\w{8}-\w{4}-\w{4}-\w{4}-\w{12}|, guid
  end
  
end
