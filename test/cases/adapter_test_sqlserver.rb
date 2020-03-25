require 'cases/helper_sqlserver'
require 'models/topic'
require 'models/task'
require 'models/post'
require 'models/subscriber'
require 'models/minimalistic'

class AdapterTestSQLServer < ActiveRecord::TestCase

  fixtures :tasks

  let(:basic_insert_sql) { "INSERT INTO [funny_jokes] ([name]) VALUES('Knock knock')" }
  let(:basic_update_sql) { "UPDATE [customers] SET [address_street] = NULL WHERE [id] = 2" }
  let(:basic_select_sql) { "SELECT * FROM [customers] WHERE ([customers].[id] = 1)" }

  it 'has basic and non-senstive information in the adpaters inspect method' do
    string = connection.inspect
    _(string).must_match %r{ActiveRecord::ConnectionAdapters::SQLServerAdapter}
    _(string).must_match %r{version\: \d.\d}
    _(string).must_match %r{mode: dblib}
    _(string).must_match %r{azure: (true|false)}
    _(string).wont_match %r{host}
    _(string).wont_match %r{password}
    _(string).wont_match %r{username}
    _(string).wont_match %r{port}
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

  it 'return unquoted table name object from basic INSERT UPDATE and SELECT statements' do
    assert_equal 'funny_jokes', connection.send(:get_table_name, basic_insert_sql)
    assert_equal 'customers', connection.send(:get_table_name, basic_update_sql)
    assert_equal 'customers', connection.send(:get_table_name, basic_select_sql)
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
        ending = Time.new(2006, 12, 31)
        Task.create! starting: starting, ending: ending
      end
    end

  end

  describe 'testing #lowercase_schema_reflection' do

    before do
      SSTestUpper.delete_all
      SSTestUpper.create COLUMN1: 'Got a minute?', COLUMN2: 419
      SSTestUpper.create COLUMN1: 'Favorite number?', COLUMN2: 69
    end

    after do
      connection.lowercase_schema_reflection = false
    end

    it 'not lowercase schema reflection by default' do
      assert SSTestUpper.columns_hash['COLUMN1']
      assert_equal 'Got a minute?', SSTestUpper.first.COLUMN1
      assert_equal 'Favorite number?', SSTestUpper.last.COLUMN1
      assert SSTestUpper.columns_hash['COLUMN2']
    end

    it 'lowercase schema reflection when set' do
      connection.lowercase_schema_reflection = true
      assert SSTestUppered.columns_hash['column1']
      assert_equal 'Got a minute?', SSTestUppered.first.column1
      assert_equal 'Favorite number?', SSTestUppered.last.column1
      assert SSTestUppered.columns_hash['column2']
    end

  end

  describe 'identity inserts' do

    before do
      @identity_insert_sql = "INSERT INTO [funny_jokes] ([id],[name]) VALUES(420,'Knock knock')"
      @identity_insert_sql_unquoted = "INSERT INTO funny_jokes (id, name) VALUES(420, 'Knock knock')"
      @identity_insert_sql_unordered = "INSERT INTO [funny_jokes] ([name],[id]) VALUES('Knock knock',420)"
      @identity_insert_sql_sp = "EXEC sp_executesql N'INSERT INTO [funny_jokes] ([id],[name]) VALUES (@0, @1)', N'@0 int, @1 nvarchar(255)', @0 = 420, @1 = N'Knock knock'"
      @identity_insert_sql_unquoted_sp = "EXEC sp_executesql N'INSERT INTO [funny_jokes] (id, name) VALUES (@0, @1)', N'@0 int, @1 nvarchar(255)', @0 = 420, @1 = N'Knock knock'"
      @identity_insert_sql_unordered_sp = "EXEC sp_executesql N'INSERT INTO [funny_jokes] ([name],[id]) VALUES (@0, @1)', N'@0 nvarchar(255), @1  int', @0 = N'Knock knock', @1 = 420"
    end

    it 'return quoted table_name to #query_requires_identity_insert? when INSERT sql contains id column' do
      assert_equal 'funny_jokes', connection.send(:query_requires_identity_insert?,@identity_insert_sql)
      assert_equal 'funny_jokes', connection.send(:query_requires_identity_insert?,@identity_insert_sql_unquoted)
      assert_equal 'funny_jokes', connection.send(:query_requires_identity_insert?,@identity_insert_sql_unordered)
      assert_equal 'funny_jokes', connection.send(:query_requires_identity_insert?,@identity_insert_sql_sp)
      assert_equal 'funny_jokes', connection.send(:query_requires_identity_insert?,@identity_insert_sql_unquoted_sp)
      assert_equal 'funny_jokes', connection.send(:query_requires_identity_insert?,@identity_insert_sql_unordered_sp)
    end

    it 'return false to #query_requires_identity_insert? for normal SQL' do
      [basic_insert_sql, basic_update_sql, basic_select_sql].each do |sql|
        assert !connection.send(:query_requires_identity_insert?,sql), "SQL was #{sql}"
      end
    end

    it 'find identity column using #identity_columns' do
      task_id_column = Task.columns_hash['id']
      assert_equal task_id_column.name, connection.send(:identity_columns, Task.table_name).first.name
      assert_equal task_id_column.sql_type, connection.send(:identity_columns, Task.table_name).first.sql_type
    end

    it 'return an empty array when calling #identity_columns for a table_name with no identity' do
      _(connection.send(:identity_columns, Subscriber.table_name)).must_equal []
    end

  end

  describe 'quoting' do

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

    it "surround string with national prefix" do
      assert_equal "N'foo'", connection.quote("foo")
    end

    it "escape all single quotes by repeating them" do
      assert_equal "N'''quotation''s'''", connection.quote("'quotation's'")
    end

  end

  describe 'disabling referential integrity' do

    before do
      connection.disable_referential_integrity { SSTestHasPk.delete_all; SSTestHasFk.delete_all }
      @parent = SSTestHasPk.create!
      @member = SSTestHasFk.create!(fk_id: @parent.id)
    end

    it 'NOT ALLOW by default the deletion of a referenced parent' do
      SSTestHasPk.connection.disable_referential_integrity { }
      assert_raise(ActiveRecord::StatementInvalid) { @parent.destroy }
    end

    it 'ALLOW deletion of referenced parent using #disable_referential_integrity block' do
      SSTestHasPk.connection.disable_referential_integrity { @parent.destroy }
    end

    it 'again NOT ALLOW deletion of referenced parent after #disable_referential_integrity block' do
      assert_raise(ActiveRecord::StatementInvalid) do
        SSTestHasPk.connection.disable_referential_integrity { }
        @parent.destroy
      end
    end

    it 'not disable referential integrity for the same table twice' do
      tables = SSTestHasPk.connection.tables_with_referential_integrity
      assert_equal tables.size, tables.uniq.size
    end

  end

  describe 'database statements' do

    it "run the database consistency checker useroptions command" do
      skip 'on azure' if connection_sqlserver_azure?
      keys = [:textsize, :language, :isolation_level, :dateformat]
      user_options = connection.user_options
      keys.each do |key|
        msg = "Expected key:#{key} in user_options:#{user_options.inspect}"
        assert user_options.key?(key), msg
      end
    end

    it "return a underscored key hash with indifferent access of the results" do
      skip 'on azure' if connection_sqlserver_azure?
      user_options = connection.user_options
      assert_equal 'read committed', user_options['isolation_level']
      assert_equal 'read committed', user_options[:isolation_level]
    end

  end

  describe 'schema statements' do

    it 'create integers when no limit supplied' do
      assert_equal 'integer', connection.type_to_sql(:integer)
    end

    it 'create integers when limit is 4' do
      assert_equal 'integer', connection.type_to_sql(:integer, limit: 4)
    end

    it 'create integers when limit is 3' do
      assert_equal 'integer', connection.type_to_sql(:integer, limit: 3)
    end

    it 'create smallints when limit is 2' do
      assert_equal 'smallint', connection.type_to_sql(:integer, limit: 2)
    end

    it 'create tinyints when limit is 1' do
      assert_equal 'tinyint', connection.type_to_sql(:integer, limit: 1)
    end

    it 'create bigints when limit is greateer than 4' do
      assert_equal 'bigint', connection.type_to_sql(:integer, limit: 5)
      assert_equal 'bigint', connection.type_to_sql(:integer, limit: 6)
      assert_equal 'bigint', connection.type_to_sql(:integer, limit: 7)
      assert_equal 'bigint', connection.type_to_sql(:integer, limit: 8)
    end

    it 'create floats when no limit supplied' do
      assert_equal 'float', connection.type_to_sql(:float)
    end

  end

  describe 'views' do

    # Using connection.views

    it 'return an array' do
      assert_instance_of Array, connection.views
    end

    it 'find SSTestCustomersView table name' do
      _(connection.views).must_include 'sst_customers_view'
    end

    it 'work with dynamic finders' do
      name = 'MetaSkills'
      customer = SSTestCustomersView.create! name: name
      assert_equal customer, SSTestCustomersView.find_by_name(name)
    end

    it 'not contain system views' do
      systables = ['sysconstraints','syssegments']
      systables.each do |systable|
        assert !connection.views.include?(systable), "This systable #{systable} should not be in the views array."
      end
    end

    it 'allow the connection#view_information method to return meta data on the view' do
      view_info = connection.send(:view_information,'sst_customers_view')
      assert_equal('sst_customers_view', view_info['TABLE_NAME'])
      assert_match(/CREATE VIEW sst_customers_view/, view_info['VIEW_DEFINITION'])
    end

    it 'allow the connection#view_table_name method to return true table_name for the view' do
      assert_equal 'customers', connection.send(:view_table_name,'sst_customers_view')
      assert_equal 'topics', connection.send(:view_table_name,'topics'), 'No view here, the same table name should come back.'
    end

    # With same column names

    it 'have matching column objects' do
      columns = ['id','name','balance']
      assert !SSTestCustomersView.columns.blank?
      assert_equal columns.size, SSTestCustomersView.columns.size
      columns.each do |colname|
        assert_instance_of ActiveRecord::ConnectionAdapters::SQLServerColumn,
          SSTestCustomersView.columns_hash[colname],
          "Column name #{colname.inspect} was not found in these columns #{SSTestCustomersView.columns.map(&:name).inspect}"
      end
    end

    it 'find identity column' do
      _(SSTestCustomersView.primary_key).must_equal 'id'
      _(connection.primary_key(SSTestCustomersView.table_name)).must_equal 'id'
      _(SSTestCustomersView.columns_hash['id']).must_be :is_identity?
    end

    it 'find default values' do
      assert_equal 0, SSTestCustomersView.new.balance
    end

    it 'respond true to data_source_exists?' do
      assert SSTestCustomersView.connection.data_source_exists?(SSTestCustomersView.table_name)
    end

    # With aliased column names

    it 'have matching column objects' do
      columns = ['id','pretend_null']
      assert !SSTestStringDefaultsView.columns.blank?
      assert_equal columns.size, SSTestStringDefaultsView.columns.size
      columns.each do |colname|
        assert_instance_of ActiveRecord::ConnectionAdapters::SQLServerColumn,
          SSTestStringDefaultsView.columns_hash[colname],
          "Column name #{colname.inspect} was not found in these columns #{SSTestStringDefaultsView.columns.map(&:name).inspect}"
      end
    end

    it 'find identity column' do
      _(SSTestStringDefaultsView.primary_key).must_equal 'id'
      _(connection.primary_key(SSTestStringDefaultsView.table_name)).must_equal 'id'
      _(SSTestStringDefaultsView.columns_hash['id']).must_be :is_identity?
    end

    it 'find default values' do
      assert_equal 'null', SSTestStringDefaultsView.new.pretend_null,
        SSTestStringDefaultsView.columns_hash['pretend_null'].inspect
    end

    it 'respond true to data_source_exists?' do
      assert SSTestStringDefaultsView.connection.data_source_exists?(SSTestStringDefaultsView.table_name)
    end

    # That have more than 4000 chars for their defintion

    it 'cope with null returned for the defintion' do
      assert_nothing_raised() { SSTestStringDefaultsBigView.columns }
    end

    it 'using alternate view defintion still be able to find real default' do
      assert_equal 'null', SSTestStringDefaultsBigView.new.pretend_null,
        SSTestStringDefaultsBigView.columns_hash['pretend_null'].inspect
    end

  end

  describe 'database_prefix_remote_server?' do

    after do
      connection_options.delete(:database_prefix)
    end

    it 'returns false if database_prefix is not configured' do
      assert_equal false, connection.database_prefix_remote_server?
    end

    it 'returns true if database_prefix has been set' do
      connection_options[:database_prefix] = "server.database.schema."
      assert_equal true, connection.database_prefix_remote_server?
    end

    it 'returns false if database_prefix has been set incorrectly' do
      connection_options[:database_prefix] = "server.database.schema"
      assert_equal false, connection.database_prefix_remote_server?
    end

  end

  it 'in_memory_oltp' do
    if ENV['IN_MEMORY_OLTP'] && connection.supports_in_memory_oltp?
      _(SSTMemory.primary_key).must_equal 'id'
      _(SSTMemory.columns_hash['id']).must_be :is_identity?
    else
      skip 'supports_in_memory_oltp? => false'
    end
  end

end

