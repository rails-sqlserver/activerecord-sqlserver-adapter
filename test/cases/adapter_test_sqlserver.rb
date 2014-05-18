require 'cases/sqlserver_helper'
require 'models/task'
require 'models/reply'
require 'models/joke'
require 'models/subscriber'
require 'models/minimalistic'
require 'models/post'
require 'models_sqlserver/fk_test_has_pk'
require 'models_sqlserver/fk_test_has_fk'
require 'models_sqlserver/customers_view'
require 'models_sqlserver/sql_server_chronic'
require 'models_sqlserver/string_defaults_big_view'
require 'models_sqlserver/string_defaults_view'
require 'models_sqlserver/topic'
require 'models_sqlserver/upper_test_default'
require 'models_sqlserver/upper_test_lowered'

class AdapterTestSqlserver < ActiveRecord::TestCase

  fixtures :tasks, :posts

  setup do
    @connection = ActiveRecord::Base.connection
    @basic_insert_sql = "INSERT INTO [funny_jokes] ([name]) VALUES('Knock knock')"
    @basic_update_sql = "UPDATE [customers] SET [address_street] = NULL WHERE [id] = 2"
    @basic_select_sql = "SELECT * FROM [customers] WHERE ([customers].[id] = 1)"
  end

  context 'For abstract behavior' do

    should 'have a 128 max #table_alias_length' do
      assert @connection.table_alias_length <= 128
    end

    should 'raise invalid statement error' do
      assert_raise(ActiveRecord::StatementInvalid) { Topic.connection.update("UPDATE XXX") }
    end

    should 'be our adapter_name' do
      assert_equal 'SQLServer', @connection.adapter_name
    end

    should 'include version in inspect' do
      assert_match(/version\: \d.\d/,@connection.inspect)
    end

    should 'include database product level in inspect' do
      assert_match(/product_level\: "\w+/, @connection.inspect)
    end

    should 'include database product version in inspect' do
      assert_match(/product_version\: "\d+/, @connection.inspect)
    end

    should 'include database edition in inspect' do
      assert_match(/edition\: "\w+/, @connection.inspect)
    end

    should 'set database product level' do
      assert_match(/\w+/, @connection.product_level)
    end

    should 'set database product version' do
      assert_match(/\d+/, @connection.product_version)
    end

    should 'set database edition' do
      assert_match(/\w+/, @connection.edition)
    end

    should 'support migrations' do
      assert @connection.supports_migrations?
    end

    should 'support DDL in transactions' do
      assert @connection.supports_ddl_transactions?
    end

    should 'allow owner table name prefixs like dbo. to still allow table_exists? to return true' do
      begin
        assert_equal 'tasks', Task.table_name
        assert Task.table_exists?
        Task.table_name = 'dbo.tasks'
        assert Task.table_exists?, 'Tasks table name of dbo.tasks should return true for exists.'
      ensure
        Task.table_name = 'tasks'
      end
    end

    context 'for database version' do

      setup do
        @version_regexp = ActiveRecord::ConnectionAdapters::SQLServerAdapter::DATABASE_VERSION_REGEXP
        @supported_versions = ActiveRecord::ConnectionAdapters::SQLServerAdapter::SUPPORTED_VERSIONS
        @sqlserver_2005_string = "Microsoft SQL Server 2005 - 9.00.3215.00 (Intel X86)"
        @sqlserver_2008_string = "Microsoft SQL Server 2008 (RTM) - 10.0.1600.22 (Intel X86)"
        @sqlserver_2011_string1 = %|Microsoft SQL Server "Denali" (CTP1) - 11.0.1103.9 (Intel X86) Sep 24 2010 22:02:43 Copyright (c) Microsoft Corporation Enterprise Evaluation Edition on Windows NT 6.0 (Build 6002: Service Pack 2)|
      end

      should 'return a string from #database_version that matches class regexp' do
        assert_match @version_regexp, @connection.database_version
      end unless sqlserver_azure?

      should 'return a 4 digit year fixnum for #database_year' do
        assert_instance_of Fixnum, @connection.database_year
        @supported_versions.must_include @connection.database_year
      end

      should 'return a code name if year not available' do
        assert_equal "Denali", @version_regexp.match(@sqlserver_2011_string1)[1]
      end

    end

    context 'for Utils.unqualify_table_name and Utils.unqualify_db_name' do

      setup do
        @expected_table_name = 'baz'
        @expected_db_name = 'foo'
        @first_second_table_names = ['[baz]','baz','[bar].[baz]','bar.baz']
        @third_table_names = ['[foo].[bar].[baz]','foo.bar.baz']
        @qualifed_table_names = @first_second_table_names + @third_table_names
      end

      should 'return clean table_name from Utils.unqualify_table_name' do
        @qualifed_table_names.each do |qtn|
          assert_equal @expected_table_name,
            ActiveRecord::ConnectionAdapters::Sqlserver::Utils.unqualify_table_name(qtn),
            "This qualifed_table_name #{qtn} did not unqualify correctly."
        end
      end

      should 'return nil from Utils.unqualify_db_name when table_name is less than 2 qualified' do
        @first_second_table_names.each do |qtn|
          assert_equal nil, ActiveRecord::ConnectionAdapters::Sqlserver::Utils.unqualify_db_name(qtn),
            "This qualifed_table_name #{qtn} did not return nil."
        end
      end

      should 'return clean db_name from Utils.unqualify_db_name when table is thrid level qualified' do
        @third_table_names.each do |qtn|
          assert_equal @expected_db_name,
            ActiveRecord::ConnectionAdapters::Sqlserver::Utils.unqualify_db_name(qtn),
            "This qualifed_table_name #{qtn} did not unqualify the db_name correctly."
        end
      end

    end

    should 'return true to #insert_sql? for inserts only' do
      assert @connection.send(:insert_sql?,'INSERT...')
      assert @connection.send(:insert_sql?, "EXEC sp_executesql N'INSERT INTO [fk_test_has_fks] ([fk_id]) VALUES (@0); SELECT CAST(SCOPE_IDENTITY() AS bigint) AS Ident', N'@0 int', @0 = 0")
      assert !@connection.send(:insert_sql?,'UPDATE...')
      assert !@connection.send(:insert_sql?,'SELECT...')
    end

    context 'for #get_table_name' do

      should 'return quoted table name from basic INSERT, UPDATE and SELECT statements' do
        assert_equal '[funny_jokes]', @connection.send(:get_table_name,@basic_insert_sql)
        assert_equal '[customers]', @connection.send(:get_table_name,@basic_update_sql)
        assert_equal '[customers]', @connection.send(:get_table_name,@basic_select_sql)
      end

    end

    context 'with different language' do

      setup do
        @default_language = @connection.user_options_language
      end

      teardown do
        @connection.execute("SET LANGUAGE #{@default_language}") rescue nil
        @connection.send :initialize_dateformatter
      end

      should 'memoize users dateformat' do
        @connection.execute("SET LANGUAGE us_english") rescue nil
        dateformat = @connection.instance_variable_get(:@database_dateformat)
        assert_equal 'mdy', dateformat
      end

      should 'have a dateformatter' do
        assert Date::DATE_FORMATS[:_sqlserver_dateformat]
        assert Time::DATE_FORMATS[:_sqlserver_dateformat]
      end

      should 'do a date insertion when language is german' do
        @connection.execute("SET LANGUAGE deutsch")
        @connection.send :initialize_dateformatter
        assert_nothing_raised do
          Task.create(starting: Time.utc(2000, 1, 31, 5, 42, 0), ending: Date.new(2006, 12, 31))
        end
      end

    end

    context 'testing #enable_default_unicode_types configuration' do

      should 'use non-unicode types when set to false' do
        with_enable_default_unicode_types(false) do
          assert_equal 'varchar', @connection.native_string_database_type
          assert_equal 'varchar(max)', @connection.native_text_database_type
        end
      end

      should 'use unicode types when set to true' do
        with_enable_default_unicode_types(true) do
          assert_equal 'nvarchar', @connection.native_string_database_type
          assert_equal 'nvarchar(max)', @connection.native_text_database_type
        end
      end

    end

    context 'testing #lowercase_schema_reflection' do

      setup do
        UpperTestDefault.delete_all
        UpperTestDefault.create COLUMN1: 'Got a minute?', COLUMN2: 419
        UpperTestDefault.create COLUMN1: 'Favorite number?', COLUMN2: 69
      end

      teardown do
        @connection.lowercase_schema_reflection = false
      end

      should 'not lowercase schema reflection by default' do
        assert UpperTestDefault.columns_hash['COLUMN1']
        assert_equal 'Got a minute?', UpperTestDefault.first.COLUMN1
        assert_equal 'Favorite number?', UpperTestDefault.last.COLUMN1
        assert UpperTestDefault.columns_hash['COLUMN2']
      end

      should 'lowercase schema reflection when set' do
        @connection.lowercase_schema_reflection = true
        UpperTestLowered.reset_column_information
        assert UpperTestLowered.columns_hash['column1']
        assert_equal 'Got a minute?', UpperTestLowered.first.column1
        assert_equal 'Favorite number?', UpperTestLowered.last.column1
        assert UpperTestLowered.columns_hash['column2']
      end

    end

  end

  context 'For chronic data types' do

    context 'with a usec' do

      setup do
        @time = Time.now
        @db_datetime_003 = '2012-11-08 10:24:36.003'
        @db_datetime_123 = '2012-11-08 10:24:36.123'
        @all_datetimes = [@db_datetime_003, @db_datetime_123]
        @all_datetimes.each do |datetime|
          @connection.execute("INSERT INTO [sql_server_chronics] ([datetime]) VALUES('#{datetime}')")
        end
      end

      teardown do
        @all_datetimes.each do |datetime|
          @connection.execute("DELETE FROM [sql_server_chronics] WHERE [datetime] = '#{datetime}'")
        end
      end

      context 'finding existing DB objects' do

        should 'find 003 millisecond in the DB with before and after casting' do
          existing_003 = SqlServerChronic.find_by_datetime!(@db_datetime_003)
          assert_equal @db_datetime_003, existing_003.datetime_before_type_cast if existing_003.datetime_before_type_cast.is_a?(String)
          assert_equal 3000, existing_003.datetime.usec, 'A 003 millisecond in SQL Server is 3000 microseconds'
        end

        should 'find 123 millisecond in the DB with before and after casting' do
          existing_123 = SqlServerChronic.find_by_datetime!(@db_datetime_123)
          assert_equal @db_datetime_123, existing_123.datetime_before_type_cast if existing_123.datetime_before_type_cast.is_a?(String)
          assert_equal 123000, existing_123.datetime.usec, 'A 123 millisecond in SQL Server is 123000 microseconds'
        end

      end

      context 'saving new datetime objects' do

        should 'truncate 123456 usec to just 123 in the DB cast back to 123000' do
          Time.any_instance.stubs iso8601: "2011-07-26T12:29:01.123-04:00"
          saved = SqlServerChronic.create!(datetime: @time).reload
          saved.reload
          assert_equal '123', saved.datetime_before_type_cast.split('.')[1] if saved.datetime_before_type_cast.is_a?(String)
          assert_equal 123000, saved.datetime.usec
        end

      end

    end

  end

  context 'For identity inserts' do

    setup do
      @identity_insert_sql = "INSERT INTO [funny_jokes] ([id],[name]) VALUES(420,'Knock knock')"
      @identity_insert_sql_unquoted = "INSERT INTO funny_jokes (id, name) VALUES(420, 'Knock knock')"
      @identity_insert_sql_unordered = "INSERT INTO [funny_jokes] ([name],[id]) VALUES('Knock knock',420)"
      @identity_insert_sql_sp = "EXEC sp_executesql N'INSERT INTO [funny_jokes] ([id],[name]) VALUES (@0, @1)', N'@0 int, @1 nvarchar(255)', @0 = 420, @1 = N'Knock knock'"
      @identity_insert_sql_unquoted_sp = "EXEC sp_executesql N'INSERT INTO [funny_jokes] (id, name) VALUES (@0, @1)', N'@0 int, @1 nvarchar(255)', @0 = 420, @1 = N'Knock knock'"
      @identity_insert_sql_unordered_sp = "EXEC sp_executesql N'INSERT INTO [funny_jokes] ([name],[id]) VALUES (@0, @1)', N'@0 nvarchar(255), @1  int', @0 = N'Knock knock', @1 = 420"
    end

    should 'return quoted table_name to #query_requires_identity_insert? when INSERT sql contains id column' do
      assert_equal '[funny_jokes]', @connection.send(:query_requires_identity_insert?,@identity_insert_sql)
      assert_equal '[funny_jokes]', @connection.send(:query_requires_identity_insert?,@identity_insert_sql_unquoted)
      assert_equal '[funny_jokes]', @connection.send(:query_requires_identity_insert?,@identity_insert_sql_unordered)
      assert_equal '[funny_jokes]', @connection.send(:query_requires_identity_insert?,@identity_insert_sql_sp)
      assert_equal '[funny_jokes]', @connection.send(:query_requires_identity_insert?,@identity_insert_sql_unquoted_sp)
      assert_equal '[funny_jokes]', @connection.send(:query_requires_identity_insert?,@identity_insert_sql_unordered_sp)
    end

    should 'return false to #query_requires_identity_insert? for normal SQL' do
      [@basic_insert_sql, @basic_update_sql, @basic_select_sql].each do |sql|
        assert !@connection.send(:query_requires_identity_insert?,sql), "SQL was #{sql}"
      end
    end

    should 'find identity column using #identity_column' do
      joke_id_column = Joke.columns.find { |c| c.name == 'id' }
      assert_equal joke_id_column.name, @connection.send(:identity_column,Joke.table_name).name
      assert_equal joke_id_column.sql_type, @connection.send(:identity_column,Joke.table_name).sql_type
    end

    should 'return nil when calling #identity_column for a table_name with no identity' do
      assert_nil @connection.send(:identity_column,Subscriber.table_name)
    end unless sqlserver_azure?

    should 'be able to disable referential integrity' do
      Minimalistic.delete_all
      @connection.send :set_identity_insert, Minimalistic.table_name, false
      @connection.execute_procedure :sp_MSforeachtable, 'ALTER TABLE ? CHECK CONSTRAINT ALL'
      o = Minimalistic.new
      o.id = 420
      o.save!
    end

  end

  context 'For Quoting' do

    should 'return 1 for #quoted_true' do
      assert_equal '1', @connection.quoted_true
    end

    should 'return 0 for #quoted_false' do
      assert_equal '0', @connection.quoted_false
    end

    should 'not escape backslash characters like abstract adapter' do
      string_with_backslashs = "\\n"
      assert_equal string_with_backslashs, @connection.quote_string(string_with_backslashs)
    end

    should 'quote column names with brackets' do
      assert_equal '[foo]', @connection.quote_column_name(:foo)
      assert_equal '[foo]', @connection.quote_column_name('foo')
      assert_equal '[foo].[bar]', @connection.quote_column_name('foo.bar')
    end

    should 'not quote already quoted column names with brackets' do
      assert_equal '[foo]', @connection.quote_column_name('[foo]')
      assert_equal '[foo].[bar]', @connection.quote_column_name('[foo].[bar]')
    end

    should 'quote table names like columns' do
      assert_equal '[foo].[bar]', @connection.quote_column_name('foo.bar')
      assert_equal '[foo].[bar].[baz]', @connection.quote_column_name('foo.bar.baz')
    end

    context "#quote" do

      context "string and multibyte values" do

        context "on an activerecord :integer column" do

          setup do
            @column = Post.columns_hash['id']
          end

          should "return 0 for empty string" do
            assert_equal '0', @connection.quote('', @column)
          end

        end

        context "on an activerecord :string column or with any value" do

          should "surround it when N'...'" do
            assert_equal "N'foo'", @connection.quote("foo")
          end

          should "escape all single quotes by repeating them" do
            assert_equal "N'''quotation''s'''", @connection.quote("'quotation's'")
          end

        end

      end

      context "date and time values" do

        setup do
          @date = Date.parse '2000-01-01'
          @column = SqlServerChronic.columns_hash['datetime']
        end

        context "on a sql datetime column" do

          should "call quoted_datetime and surrounds its result with single quotes" do
            assert_equal "'01-01-2000'", @connection.quote(@date, @column)
          end

        end

      end

    end

    context "#quoted_datetime" do

      setup do
        @iso_string = '2001-02-03T04:05:06-0700'
        @date = Date.parse @iso_string
        @time = Time.parse @iso_string
        @datetime = DateTime.parse @iso_string
      end

      context "with a Date" do

        should "return a dd-mm-yyyy date string" do
          assert_equal '02-03-2001', @connection.quoted_datetime(@date)
        end

      end

      context "when the ActiveRecord default timezone is UTC" do

        setup do
          @old_activerecord_timezone = ActiveRecord::Base.default_timezone
          ActiveRecord::Base.default_timezone = :utc
        end

        teardown do
          ActiveRecord::Base.default_timezone = @old_activerecord_timezone
          @old_activerecord_timezone = nil
        end

        context "with a Time" do

          should "return an ISO 8601 datetime string" do
            assert_equal '2001-02-03T11:05:06.000', @connection.quoted_datetime(@time)
          end

        end

        context "with a DateTime" do

          should "return an ISO 8601 datetime string" do
            assert_equal '2001-02-03T11:05:06', @connection.quoted_datetime(@datetime)
          end

        end

        context "with an ActiveSupport::TimeWithZone" do

          context "wrapping a datetime" do

            should "return an ISO 8601 datetime string with milliseconds" do
              Time.use_zone('Eastern Time (US & Canada)') do
                assert_equal '2001-02-03T11:05:06.000', @connection.quoted_datetime(@datetime.in_time_zone)
              end
            end

          end

          context "wrapping a time" do

            should "return an ISO 8601 datetime string with milliseconds" do
              Time.use_zone('Eastern Time (US & Canada)') do
                assert_equal '2001-02-03T11:05:06.000', @connection.quoted_datetime(@time.in_time_zone)
              end
            end

          end

        end

      end

    end

  end

  context 'When disabling referential integrity' do

    setup do
      @connection.disable_referential_integrity { FkTestHasPk.delete_all; FkTestHasFk.delete_all }
      @parent = FkTestHasPk.create!
      @member = FkTestHasFk.create!(fk_id: @parent.id)
    end

    should 'NOT ALLOW by default the deletion of a referenced parent' do
      FkTestHasPk.connection.disable_referential_integrity { }
      assert_raise(ActiveRecord::StatementInvalid) { @parent.destroy }
    end

    should 'ALLOW deletion of referenced parent using #disable_referential_integrity block' do
      FkTestHasPk.connection.disable_referential_integrity { @parent.destroy }
    end

    should 'again NOT ALLOW deletion of referenced parent after #disable_referential_integrity block' do
      assert_raise(ActiveRecord::StatementInvalid) do
        FkTestHasPk.connection.disable_referential_integrity { }
        @parent.destroy
      end
    end

  end

  context 'For DatabaseStatements' do

    context "finding out what user_options are available" do

      should "run the database consistency checker useroptions command" do
        keys = [:textsize, :language, :isolation_level, :dateformat]
        user_options = @connection.user_options
        keys.each do |key|
          msg = "Expected key:#{key} in user_options:#{user_options.inspect}"
          assert user_options.key?(key), msg
        end
      end

      should "return a underscored key hash with indifferent access of the results" do
        user_options = @connection.user_options
        assert_equal 'read committed', user_options['isolation_level']
        assert_equal 'read committed', user_options[:isolation_level]
      end

    end unless sqlserver_azure?

    context "altering isolation levels" do

      should "barf if the requested isolation level is not valid" do
        assert_raise(ArgumentError) do
          @connection.run_with_isolation_level 'INVALID ISOLATION LEVEL' do; end
        end
      end

      context "with a valid isolation level" do

        setup do
          @t1 = tasks(:first_task)
          @t2 = tasks(:another_task)
          assert @t1, 'Tasks :first_task should be in AR fixtures'
          assert @t2, 'Tasks :another_task should be in AR fixtures'
          good_isolation_level = @connection.user_options_isolation_level.blank? || @connection.user_options_isolation_level =~ /read committed/i
          assert good_isolation_level, "User isolation level is not at a happy starting place: #{@connection.user_options_isolation_level.inspect}"
        end

        should 'allow #run_with_isolation_level to not take a block to set it' do
          begin
            @connection.run_with_isolation_level 'READ UNCOMMITTED'
            assert_match %r|read uncommitted|i, @connection.user_options_isolation_level
          ensure
            @connection.run_with_isolation_level 'READ COMMITTED'
          end
        end

        should 'return block value using #run_with_isolation_level' do
          assert_equal Task.all.sort, @connection.run_with_isolation_level('READ UNCOMMITTED') { Task.all.sort }
        end

        should 'pass a read uncommitted isolation level test' do
          assert_nil @t2.starting, 'Fixture should have this empty.'
          begin
            Task.transaction do
              @t2.starting = Time.now
              @t2.save
              @dirty_t2 = @connection.run_with_isolation_level('READ UNCOMMITTED') { Task.find(@t2.id) }
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

  context 'For SchemaStatements' do

    context 'returning from #type_to_sql' do

      should 'create integers when no limit supplied' do
        assert_equal 'integer', @connection.type_to_sql(:integer)
      end

      should 'create integers when limit is 4' do
        assert_equal 'integer', @connection.type_to_sql(:integer, 4)
      end

      should 'create integers when limit is 3' do
        assert_equal 'integer', @connection.type_to_sql(:integer, 3)
      end

      should 'create smallints when limit is less than 3' do
        assert_equal 'smallint', @connection.type_to_sql(:integer, 2)
        assert_equal 'smallint', @connection.type_to_sql(:integer, 1)
      end

      should 'create bigints when limit is greateer than 4' do
        assert_equal 'bigint', @connection.type_to_sql(:integer, 5)
        assert_equal 'bigint', @connection.type_to_sql(:integer, 6)
        assert_equal 'bigint', @connection.type_to_sql(:integer, 7)
        assert_equal 'bigint', @connection.type_to_sql(:integer, 8)
      end

      should 'create floats when no limit supplied' do
        assert_equal 'float(8)', @connection.type_to_sql(:float)
      end

      should 'create floats when limit is supplied' do
        assert_equal 'float(27)', @connection.type_to_sql(:float, 27)
      end

    end

  end

  context 'For indexes' do

    setup do
      @desc_index_name = 'idx_credit_limit_test_desc'
      @connection.execute "CREATE INDEX [#{@desc_index_name}] ON [accounts] (credit_limit DESC)"
    end

    teardown do
      @connection.execute "DROP INDEX [#{@desc_index_name}] ON [accounts]"
    end

    should 'have indexes with descending order' do
      assert @connection.indexes('accounts').find { |i| i.name == @desc_index_name }
    end

  end

  context 'For views' do

    context 'using @connection.views' do

      should 'return an array' do
        assert_instance_of Array, @connection.views
      end

      should 'find CustomersView table name' do
        @connection.views.must_include 'customers_view'
      end

      should 'work with dynamic finders' do
        name = 'MetaSkills'
        customer = CustomersView.create! name: name
        assert_equal customer, CustomersView.find_by_name(name)
      end

      should 'not contain system views' do
        systables = ['sysconstraints','syssegments']
        systables.each do |systable|
          assert !@connection.views.include?(systable), "This systable #{systable} should not be in the views array."
        end
      end

      should 'allow the connection#view_information method to return meta data on the view' do
        view_info = @connection.send(:view_information,'customers_view')
        assert_equal('customers_view', view_info['TABLE_NAME'])
        assert_match(/CREATE VIEW customers_view/, view_info['VIEW_DEFINITION'])
      end

      should 'allow the connection#view_table_name method to return true table_name for the view' do
        assert_equal 'customers', @connection.send(:view_table_name,'customers_view')
        assert_equal 'topics', @connection.send(:view_table_name,'topics'), 'No view here, the same table name should come back.'
      end

    end

    context 'used by a class for table_name' do

      context 'with same column names' do

        should 'have matching column objects' do
          columns = ['id','name','balance']
          assert !CustomersView.columns.blank?
          assert_equal columns.size, CustomersView.columns.size
          columns.each do |colname|
            assert_instance_of ActiveRecord::ConnectionAdapters::SQLServerColumn,
              CustomersView.columns_hash[colname],
              "Column name #{colname.inspect} was not found in these columns #{CustomersView.columns.map(&:name).inspect}"
          end
        end

        should 'find identity column' do
          assert CustomersView.columns_hash['id'].primary
        end

        should 'find default values' do
          assert_equal 0, CustomersView.new.balance
        end

        should 'respond true to table_exists?' do
          assert CustomersView.table_exists?
        end

        should 'have correct table name for all column objects' do
          assert CustomersView.columns.all?{ |c| c.table_name == 'customers_view' },
            CustomersView.columns.map(&:table_name).inspect
        end

      end

      context 'with aliased column names' do

        should 'have matching column objects' do
          columns = ['id','pretend_null']
          assert !StringDefaultsView.columns.blank?
          assert_equal columns.size, StringDefaultsView.columns.size
          columns.each do |colname|
            assert_instance_of ActiveRecord::ConnectionAdapters::SQLServerColumn,
              StringDefaultsView.columns_hash[colname],
              "Column name #{colname.inspect} was not found in these columns #{StringDefaultsView.columns.map(&:name).inspect}"
          end
        end

        should 'find identity column' do
          assert StringDefaultsView.columns_hash['id'].primary
        end

        should 'find default values' do
          assert_equal 'null', StringDefaultsView.new.pretend_null,
            StringDefaultsView.columns_hash['pretend_null'].inspect
        end

        should 'respond true to table_exists?' do
          assert StringDefaultsView.table_exists?
        end

        should 'have correct table name for all column objects' do
          assert StringDefaultsView.columns.all?{ |c| c.table_name == 'string_defaults_view' },
            StringDefaultsView.columns.map(&:table_name).inspect
        end

      end

    end

    context 'doing identity inserts' do

      setup do
        @view_insert_sql = "INSERT INTO [customers_view] ([id],[name],[balance]) VALUES (420,'Microsoft',0)"
      end

      should 'respond true/tablename to #query_requires_identity_insert?' do
        assert_equal '[customers_view]', @connection.send(:query_requires_identity_insert?,@view_insert_sql)
      end

      should 'be able to do an identity insert' do
        assert_nothing_raised { @connection.execute(@view_insert_sql) }
        assert CustomersView.find(420)
      end

    end

    context 'that have more than 4000 chars for their defintion' do

      should 'cope with null returned for the defintion' do
        assert_nothing_raised() { StringDefaultsBigView.columns }
      end

      should 'using alternate view defintion still be able to find real default' do
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
    include SqlserverCoercedTest

    fixtures :authors
  end
end
