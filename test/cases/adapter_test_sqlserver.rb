require 'cases/helper_sqlserver'
require 'models/topic'
require 'models/task'

# require 'models/reply'
# require 'models/joke'
# require 'models/subscriber'
# require 'models/minimalistic'
# require 'models/post'
# require 'models/sqlserver/fk_test_has_pk'
# require 'models/sqlserver/fk_test_has_fk'
# require 'models/sqlserver/customers_view'
# require 'models/sqlserver/string_defaults_big_view'
# require 'models/sqlserver/string_defaults_view'
# require 'models/sqlserver/topic'
# require 'models/sqlserver/upper_test_default'
# require 'models/sqlserver/upper_test_lowered'

class AdapterTestSQLServer < ActiveRecord::TestCase

  let(:connection) { ActiveRecord::Base.connection }

  let(:basic_insert_sql) { "INSERT INTO [funny_jokes] ([name]) VALUES('Knock knock')" }
  let(:basic_update_sql) { "UPDATE [customers] SET [address_street] = NULL WHERE [id] = 2" }
  let(:basic_select_sql) { "SELECT * FROM [customers] WHERE ([customers].[id] = 1)" }


  it 'has basic and non-senstive information in the adpaters inspect method' do
    string = connection.inspect
    string.must_match %r{ActiveRecord::ConnectionAdapters::SQLServerAdapter}
    string.must_match %r{version\: \d.\d}
    string.must_match %r{mode: (dblib|odbc)}
    string.must_match %r{azure: (true|false)}
    string.wont_match %r{host}
    string.wont_match %r{password}
    string.wont_match %r{username}
    string.wont_match %r{port}
  end

  it 'has a 128 max #table_alias_length' do
    assert connection.table_alias_length <= 128
  end

  it 'raises invalid statement error for bad SQL' do
    assert_raise(ActiveRecord::StatementInvalid) { Topic.connection.update("UPDATE XXX") }
  end

  it 'is has our adapter_name' do
    assert_equal 'SQLServer', connection.adapter_name
  end

  it 'supports migrations' do
    assert connection.supports_migrations?
  end

  it 'support DDL in transactions' do
    assert connection.supports_ddl_transactions?
  end

  it 'allow owner table name prefixs like dbo to still allow table exists to return true' do
    begin
      assert_equal 'topics', Topic.table_name
      assert Topic.table_exists?
      Topic.table_name = 'dbo.topics'
      assert Topic.table_exists?, 'Tasks table name of dbo.topics should return true for exists.'
    ensure
      Topic.table_name = 'topics'
    end
  end

  it 'return true to insert sql query for inserts only' do
    assert connection.send(:insert_sql?,'INSERT...')
    assert connection.send(:insert_sql?, "EXEC sp_executesql N'INSERT INTO [fk_test_has_fks] ([fk_id]) VALUES (@0); SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident', N'@0 int', @0 = 0")
    assert !connection.send(:insert_sql?,'UPDATE...')
    assert !connection.send(:insert_sql?,'SELECT...')
  end

  it 'return quoted table name from basic INSERT UPDATE and SELECT statements' do
    assert_equal '[funny_jokes]', connection.send(:get_table_name, basic_insert_sql)
    assert_equal '[customers]', connection.send(:get_table_name, basic_update_sql)
    assert_equal '[customers]', connection.send(:get_table_name, basic_select_sql)
  end

  describe 'with different language' do

    before do
      @default_language = connection.user_options_language
    end

    after do
      connection.execute("SET LANGUAGE #{@default_language}") rescue nil
      connection.send :initialize_dateformatter
    end

    it 'memos users dateformat' do
      connection.execute("SET LANGUAGE us_english") rescue nil
      dateformat = connection.instance_variable_get(:@database_dateformat)
      assert_equal 'mdy', dateformat
    end

    it 'has a dateformatter' do
      assert Date::DATE_FORMATS[:_sqlserver_dateformat]
      assert Time::DATE_FORMATS[:_sqlserver_dateformat]
    end

    it 'does a datetime insertion when language is german' do
      connection.execute("SET LANGUAGE deutsch")
      connection.send :initialize_dateformatter
      assert_nothing_raised do
        starting = Time.utc(2000, 1, 31, 5, 42, 0)
        ending = Date.new(2006, 12, 31)
        Task.create! starting: starting, ending: ending
      end
    end

  end

  describe 'testing #lowercase_schema_reflection' do

    before do
      UpperTestDefault.delete_all
      UpperTestDefault.create COLUMN1: 'Got a minute?', COLUMN2: 419
      UpperTestDefault.create COLUMN1: 'Favorite number?', COLUMN2: 69
    end

    after do
      connection.lowercase_schema_reflection = false
    end

    it 'not lowercase schema reflection by default' do
      assert UpperTestDefault.columns_hash['COLUMN1']
      assert_equal 'Got a minute?', UpperTestDefault.first.COLUMN1
      assert_equal 'Favorite number?', UpperTestDefault.last.COLUMN1
      assert UpperTestDefault.columns_hash['COLUMN2']
    end

    it 'lowercase schema reflection when set' do
      connection.lowercase_schema_reflection = true
      UpperTestLowered.reset_column_information
      assert UpperTestLowered.columns_hash['column1']
      assert_equal 'Got a minute?', UpperTestLowered.first.column1
      assert_equal 'Favorite number?', UpperTestLowered.last.column1
      assert UpperTestLowered.columns_hash['column2']
    end

  end

  describe 'For identity inserts' do

    before do
      @identity_insert_sql = "INSERT INTO [funny_jokes] ([id],[name]) VALUES(420,'Knock knock')"
      @identity_insert_sql_unquoted = "INSERT INTO funny_jokes (id, name) VALUES(420, 'Knock knock')"
      @identity_insert_sql_unordered = "INSERT INTO [funny_jokes] ([name],[id]) VALUES('Knock knock',420)"
      @identity_insert_sql_sp = "EXEC sp_executesql N'INSERT INTO [funny_jokes] ([id],[name]) VALUES (@0, @1)', N'@0 int, @1 nvarchar(255)', @0 = 420, @1 = N'Knock knock'"
      @identity_insert_sql_unquoted_sp = "EXEC sp_executesql N'INSERT INTO [funny_jokes] (id, name) VALUES (@0, @1)', N'@0 int, @1 nvarchar(255)', @0 = 420, @1 = N'Knock knock'"
      @identity_insert_sql_unordered_sp = "EXEC sp_executesql N'INSERT INTO [funny_jokes] ([name],[id]) VALUES (@0, @1)', N'@0 nvarchar(255), @1  int', @0 = N'Knock knock', @1 = 420"
    end

    it 'return quoted table_name to #query_requires_identity_insert? when INSERT sql contains id column' do
      assert_equal '[funny_jokes]', connection.send(:query_requires_identity_insert?,@identity_insert_sql)
      assert_equal '[funny_jokes]', connection.send(:query_requires_identity_insert?,@identity_insert_sql_unquoted)
      assert_equal '[funny_jokes]', connection.send(:query_requires_identity_insert?,@identity_insert_sql_unordered)
      assert_equal '[funny_jokes]', connection.send(:query_requires_identity_insert?,@identity_insert_sql_sp)
      assert_equal '[funny_jokes]', connection.send(:query_requires_identity_insert?,@identity_insert_sql_unquoted_sp)
      assert_equal '[funny_jokes]', connection.send(:query_requires_identity_insert?,@identity_insert_sql_unordered_sp)
    end

    it 'return false to #query_requires_identity_insert? for normal SQL' do
      [basic_insert_sql, basic_update_sql, basic_select_sql].each do |sql|
        assert !connection.send(:query_requires_identity_insert?,sql), "SQL was #{sql}"
      end
    end

    it 'find identity column using #identity_column' do
      joke_id_column = Joke.columns.find { |c| c.name == 'id' }
      assert_equal joke_id_column.name, connection.send(:identity_column,Joke.table_name).name
      assert_equal joke_id_column.sql_type, connection.send(:identity_column,Joke.table_name).sql_type
    end

    it 'return nil when calling #identity_column for a table_name with no identity' do
      assert_nil connection.send(:identity_column,Subscriber.table_name)
    end unless sqlserver_azure?

    it 'be able to disable referential integrity' do
      Minimalistic.delete_all
      connection.send :set_identity_insert, Minimalistic.table_name, false
      connection.execute_procedure :sp_MSforeachtable, 'ALTER TABLE ? CHECK CONSTRAINT ALL'
      o = Minimalistic.new
      o.id = 420
      o.save!
    end

  end

  describe 'For Quoting' do

    it 'return 1 for #quoted_true' do
      assert_equal '1', connection.quoted_true
    end

    it 'return 0 for #quoted_false' do
      assert_equal '0', connection.quoted_false
    end

    it 'not escape backslash characters like abstract adapter' do
      string_with_backslashs = "\\n"
      assert_equal string_with_backslashs, connection.quote_string(string_with_backslashs)
    end

    it 'quote column names with brackets' do
      assert_equal '[foo]', connection.quote_column_name(:foo)
      assert_equal '[foo]', connection.quote_column_name('foo')
      assert_equal '[foo].[bar]', connection.quote_column_name('foo.bar')
    end

    it 'not quote already quoted column names with brackets' do
      assert_equal '[foo]', connection.quote_column_name('[foo]')
      assert_equal '[foo].[bar]', connection.quote_column_name('[foo].[bar]')
    end

    it 'quote table names like columns' do
      assert_equal '[foo].[bar]', connection.quote_column_name('foo.bar')
      assert_equal '[foo].[bar].[baz]', connection.quote_column_name('foo.bar.baz')
    end

    describe "#quote" do

      describe "string and multibyte values" do

        describe "on an activerecord :integer column" do

          before do
            @column = Post.columns_hash['id']
          end

          it "return 0 for empty string" do
            assert_equal '0', connection.quote('', @column)
          end

        end

        describe "on an activerecord :string column or with any value" do

          it "surround it when N'...'" do
            assert_equal "N'foo'", connection.quote("foo")
          end

          it "escape all single quotes by repeating them" do
            assert_equal "N'''quotation''s'''", connection.quote("'quotation's'")
          end

        end

      end

    end

    describe "#quoted_datetime" do

      before do
        @iso_string = '2001-02-03T04:05:06-0700'
        @date = Date.parse @iso_string
        @time = Time.parse @iso_string
        @datetime = DateTime.parse @iso_string
      end

      describe "with a Date" do

        it "return a dd-mm-yyyy date string" do
          assert_equal '02-03-2001', connection.quoted_datetime(@date)
        end

      end

      describe "when the ActiveRecord default timezone is UTC" do

        before do
          @old_activerecord_timezone = ActiveRecord::Base.default_timezone
          ActiveRecord::Base.default_timezone = :utc
        end

        after do
          ActiveRecord::Base.default_timezone = @old_activerecord_timezone
          @old_activerecord_timezone = nil
        end

        describe "with a Time" do

          it "return an ISO 8601 datetime string" do
            assert_equal '2001-02-03T11:05:06.000', connection.quoted_datetime(@time)
          end

        end

        describe "with a DateTime" do

          it "return an ISO 8601 datetime string" do
            assert_equal '2001-02-03T11:05:06', connection.quoted_datetime(@datetime)
          end

        end

        describe "with an ActiveSupport::TimeWithZone" do

          describe "wrapping a datetime" do

            it "return an ISO 8601 datetime string with milliseconds" do
              Time.use_zone('Eastern Time (US & Canada)') do
                assert_equal '2001-02-03T11:05:06.000', connection.quoted_datetime(@datetime.in_time_zone)
              end
            end

          end

          describe "wrapping a time" do

            it "return an ISO 8601 datetime string with milliseconds" do
              Time.use_zone('Eastern Time (US & Canada)') do
                assert_equal '2001-02-03T11:05:06.000', connection.quoted_datetime(@time.in_time_zone)
              end
            end

          end

        end

      end

    end

  end

  describe 'When disabling referential integrity' do

    before do
      connection.disable_referential_integrity { FkTestHasPk.delete_all; FkTestHasFk.delete_all }
      @parent = FkTestHasPk.create!
      @member = FkTestHasFk.create!(fk_id: @parent.id)
    end

    it 'NOT ALLOW by default the deletion of a referenced parent' do
      FkTestHasPk.connection.disable_referential_integrity { }
      assert_raise(ActiveRecord::StatementInvalid) { @parent.destroy }
    end

    it 'ALLOW deletion of referenced parent using #disable_referential_integrity block' do
      FkTestHasPk.connection.disable_referential_integrity { @parent.destroy }
    end

    it 'again NOT ALLOW deletion of referenced parent after #disable_referential_integrity block' do
      assert_raise(ActiveRecord::StatementInvalid) do
        FkTestHasPk.connection.disable_referential_integrity { }
        @parent.destroy
      end
    end

  end

  describe 'For DatabaseStatements' do

    describe "finding out what user_options are available" do

      it "run the database consistency checker useroptions command" do
        keys = [:textsize, :language, :isolation_level, :dateformat]
        user_options = connection.user_options
        keys.each do |key|
          msg = "Expected key:#{key} in user_options:#{user_options.inspect}"
          assert user_options.key?(key), msg
        end
      end

      it "return a underscored key hash with indifferent access of the results" do
        user_options = connection.user_options
        assert_equal 'read committed', user_options['isolation_level']
        assert_equal 'read committed', user_options[:isolation_level]
      end

    end unless sqlserver_azure?

    describe "altering isolation levels" do

      it "barf if the requested isolation level is not valid" do
        assert_raise(ArgumentError) do
          connection.run_with_isolation_level 'INVALID ISOLATION LEVEL' do; end
        end
      end

      describe "with a valid isolation level" do

        before do
          @t1 = tasks(:first_task)
          @t2 = tasks(:another_task)
          assert @t1, 'Tasks :first_task should be in AR fixtures'
          assert @t2, 'Tasks :another_task should be in AR fixtures'
          good_isolation_level = connection.user_options_isolation_level.blank? || connection.user_options_isolation_level =~ /read committed/i
          assert good_isolation_level, "User isolation level is not at a happy starting place: #{connection.user_options_isolation_level.inspect}"
        end

        it 'allow #run_with_isolation_level to not take a block to set it' do
          begin
            connection.run_with_isolation_level 'READ UNCOMMITTED'
            assert_match %r|read uncommitted|i, connection.user_options_isolation_level
          ensure
            connection.run_with_isolation_level 'READ COMMITTED'
          end
        end

        it 'return block value using #run_with_isolation_level' do
          assert_equal Task.all.sort, connection.run_with_isolation_level('READ UNCOMMITTED') { Task.all.sort }
        end

        it 'pass a read uncommitted isolation level test' do
          assert_nil @t2.starting, 'Fixture should have this empty.'
          begin
            Task.transaction do
              @t2.starting = Time.now
              @t2.save
              @dirty_t2 = connection.run_with_isolation_level('READ UNCOMMITTED') { Task.find(@t2.id) }
              raise ActiveRecord::ActiveRecordError
            end
          rescue
            'Do Nothing'
          end
          assert @dirty_t2, 'Should have a Task record from within block above.'
          assert @dirty_t2.starting, 'Should have a dirty date.'
          assert_nil Task.find(@t2.id).starting, 'Should be nil again from botched transaction above.'
        end

      end unless sqlserver_azure?

    end

  end

  describe 'For SchemaStatements' do

    describe 'returning from #type_to_sql' do

      it 'create integers when no limit supplied' do
        assert_equal 'integer', connection.type_to_sql(:integer)
      end

      it 'create integers when limit is 4' do
        assert_equal 'integer', connection.type_to_sql(:integer, 4)
      end

      it 'create integers when limit is 3' do
        assert_equal 'integer', connection.type_to_sql(:integer, 3)
      end

      it 'create smallints when limit is less than 3' do
        assert_equal 'smallint', connection.type_to_sql(:integer, 2)
        assert_equal 'smallint', connection.type_to_sql(:integer, 1)
      end

      it 'create bigints when limit is greateer than 4' do
        assert_equal 'bigint', connection.type_to_sql(:integer, 5)
        assert_equal 'bigint', connection.type_to_sql(:integer, 6)
        assert_equal 'bigint', connection.type_to_sql(:integer, 7)
        assert_equal 'bigint', connection.type_to_sql(:integer, 8)
      end

      it 'create floats when no limit supplied' do
        assert_equal 'float(8)', connection.type_to_sql(:float)
      end

      it 'create floats when limit is supplied' do
        assert_equal 'float(27)', connection.type_to_sql(:float, 27)
      end

    end

  end

  describe 'For indexes' do

    before do
      @desc_index_name = 'idx_credit_limit_test_desc'
      connection.execute "CREATE INDEX [#{@desc_index_name}] ON [accounts] (credit_limit DESC)"
    end

    after do
      connection.execute "DROP INDEX [#{@desc_index_name}] ON [accounts]"
    end

    it 'have indexes with descending order' do
      assert connection.indexes('accounts').find { |i| i.name == @desc_index_name }
    end

  end

  describe 'For views' do

    describe 'using connection.views' do

      it 'return an array' do
        assert_instance_of Array, connection.views
      end

      it 'find CustomersView table name' do
        connection.views.must_include 'customers_view'
      end

      it 'work with dynamic finders' do
        name = 'MetaSkills'
        customer = CustomersView.create! name: name
        assert_equal customer, CustomersView.find_by_name(name)
      end

      it 'not contain system views' do
        systables = ['sysconstraints','syssegments']
        systables.each do |systable|
          assert !connection.views.include?(systable), "This systable #{systable} should not be in the views array."
        end
      end

      it 'allow the connection#view_information method to return meta data on the view' do
        view_info = connection.send(:view_information,'customers_view')
        assert_equal('customers_view', view_info['TABLE_NAME'])
        assert_match(/CREATE VIEW customers_view/, view_info['VIEW_DEFINITION'])
      end

      it 'allow the connection#view_table_name method to return true table_name for the view' do
        assert_equal 'customers', connection.send(:view_table_name,'customers_view')
        assert_equal 'topics', connection.send(:view_table_name,'topics'), 'No view here, the same table name should come back.'
      end

    end

    describe 'used by a class for table_name' do

      describe 'with same column names' do

        it 'have matching column objects' do
          columns = ['id','name','balance']
          assert !CustomersView.columns.blank?
          assert_equal columns.size, CustomersView.columns.size
          columns.each do |colname|
            assert_instance_of ActiveRecord::ConnectionAdapters::SQLServerColumn,
              CustomersView.columns_hash[colname],
              "Column name #{colname.inspect} was not found in these columns #{CustomersView.columns.map(&:name).inspect}"
          end
        end

        it 'find identity column' do
          assert CustomersView.columns_hash['id'].primary
        end

        it 'find default values' do
          assert_equal 0, CustomersView.new.balance
        end

        it 'respond true to table_exists?' do
          assert CustomersView.table_exists?
        end

        it 'have correct table name for all column objects' do
          assert CustomersView.columns.all?{ |c| c.table_name == 'customers_view' },
            CustomersView.columns.map(&:table_name).inspect
        end

      end

      describe 'with aliased column names' do

        it 'have matching column objects' do
          columns = ['id','pretend_null']
          assert !StringDefaultsView.columns.blank?
          assert_equal columns.size, StringDefaultsView.columns.size
          columns.each do |colname|
            assert_instance_of ActiveRecord::ConnectionAdapters::SQLServerColumn,
              StringDefaultsView.columns_hash[colname],
              "Column name #{colname.inspect} was not found in these columns #{StringDefaultsView.columns.map(&:name).inspect}"
          end
        end

        it 'find identity column' do
          assert StringDefaultsView.columns_hash['id'].primary
        end

        it 'find default values' do
          assert_equal 'null', StringDefaultsView.new.pretend_null,
            StringDefaultsView.columns_hash['pretend_null'].inspect
        end

        it 'respond true to table_exists?' do
          assert StringDefaultsView.table_exists?
        end

        it 'have correct table name for all column objects' do
          assert StringDefaultsView.columns.all?{ |c| c.table_name == 'string_defaults_view' },
            StringDefaultsView.columns.map(&:table_name).inspect
        end

      end

    end

    describe 'doing identity inserts' do

      before do
        @view_insert_sql = "INSERT INTO [customers_view] ([id],[name],[balance]) VALUES (420,'Microsoft',0)"
      end

      it 'respond true/tablename to #query_requires_identity_insert?' do
        assert_equal '[customers_view]', connection.send(:query_requires_identity_insert?,@view_insert_sql)
      end

      it 'be able to do an identity insert' do
        assert_nothing_raised { connection.execute(@view_insert_sql) }
        assert CustomersView.find(420)
      end

    end

    describe 'that have more than 4000 chars for their defintion' do

      it 'cope with null returned for the defintion' do
        assert_nothing_raised() { StringDefaultsBigView.columns }
      end

      it 'using alternate view defintion still be able to find real default' do
        assert_equal 'null', StringDefaultsBigView.new.pretend_null,
          StringDefaultsBigView.columns_hash['pretend_null'].inspect
      end

    end

  end

end


module ActiveRecord
  class AdapterTest < ActiveRecord::TestCase

    COERCED_TESTS = [:test_update_prepared_statement]
    # Like PostgreSQL, SQL Server does not support null bytes in strings.
    # DECLARE @mybin1 binary(5), @mybin2 binary(5)
    # SET @mybin1 = 0x00
    # SELECT 'a'+CONVERT(varchar(5), @mybin1) + 'aaaaa'
    # This is not run for PostgreSQL at the rails level and the same should happen for SQL Server
    # Until that patch is made to rails we are preventing this test from running in this gem.
    include ARTest::SQLServer::CoercedTest

    fixtures :authors
  end
end
