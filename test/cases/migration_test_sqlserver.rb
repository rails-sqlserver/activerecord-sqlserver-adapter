require 'cases/helper_sqlserver'
require 'models/person'

class MigrationTestSQLServer < ActiveRecord::TestCase

  describe 'For transactions' do

    before do
      @trans_test_table1 = 'sqlserver_trans_table1'
      @trans_test_table2 = 'sqlserver_trans_table2'
      @trans_tables = [@trans_test_table1,@trans_test_table2]
    end

    after do
      @trans_tables.each do |table_name|
        ActiveRecord::Migration.drop_table(table_name) if connection.tables.include?(table_name)
      end
    end

    it 'not create a tables if error in migrations' do
      begin
        migrations_dir = File.join ARTest::SQLServer.migrations_root, 'transaction_table'
        quietly { ActiveRecord::MigrationContext.new(migrations_dir).up }
      rescue Exception => e
        assert_match %r|this and all later migrations canceled|, e.message
      end
      _(connection.tables).wont_include @trans_test_table1
      _(connection.tables).wont_include @trans_test_table2
    end

  end

  describe 'For changing column' do

    it 'not raise exception when column contains default constraint' do
      lock_version_column = Person.columns_hash['lock_version']
      assert_equal :integer, lock_version_column.type
      assert lock_version_column.default.present?
      assert_nothing_raised { connection.change_column 'people', 'lock_version', :string }
      Person.reset_column_information
      lock_version_column = Person.columns_hash['lock_version']
      assert_equal :string, lock_version_column.type
      assert lock_version_column.default.nil?
      assert_nothing_raised { connection.change_column 'people', 'lock_version', :integer }
      Person.reset_column_information
    end

    it 'not drop the default contraint if just renaming' do
      find_default = lambda do
        connection.execute_procedure(:sp_helpconstraint, 'sst_string_defaults', 'nomsg').select do |row|
          row['constraint_type'] == "DEFAULT on column string_with_pretend_paren_three"
        end.last
      end
      default_before = find_default.call
      connection.change_column :sst_string_defaults, :string_with_pretend_paren_three, :string, limit: 255
      default_after = find_default.call
      assert default_after
      assert_equal default_before['constraint_keys'], default_after['constraint_keys']
    end
    
    it 'change limit' do
      assert_nothing_raised { connection.change_column :people, :lock_version, :integer, limit: 8 }
    end
    
    it 'change null and default' do
      assert_nothing_raised { connection.change_column :people, :first_name, :text, null: true, default: nil }
    end

  end

end
