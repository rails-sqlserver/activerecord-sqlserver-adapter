require 'base64'
require 'active_record'
require 'arel_sqlserver'
require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/sqlserver/core_ext/active_record'
require 'active_record/connection_adapters/sqlserver/core_ext/explain'
require 'active_record/connection_adapters/sqlserver/core_ext/explain_subscriber'
require 'active_record/connection_adapters/sqlserver/core_ext/relation'
require 'active_record/connection_adapters/sqlserver/version'
require 'active_record/connection_adapters/sqlserver/type'
require 'active_record/connection_adapters/sqlserver/database_limits'
require 'active_record/connection_adapters/sqlserver/database_statements'
require 'active_record/connection_adapters/sqlserver/errors'
require 'active_record/connection_adapters/sqlserver/schema_cache'
require 'active_record/connection_adapters/sqlserver/schema_creation'
require 'active_record/connection_adapters/sqlserver/schema_statements'
require 'active_record/connection_adapters/sqlserver/showplan'
require 'active_record/connection_adapters/sqlserver/table_definition'
require 'active_record/connection_adapters/sqlserver/quoting'
require 'active_record/connection_adapters/sqlserver/utils'
require 'active_record/sqlserver_base'
require 'active_record/connection_adapters/sqlserver_column'

module ActiveRecord
  module ConnectionAdapters
    class SQLServerAdapter < AbstractAdapter

      include SQLServer::Version,
              SQLServer::Quoting,
              SQLServer::DatabaseStatements,
              SQLServer::Showplan,
              SQLServer::SchemaStatements,
              SQLServer::DatabaseLimits,
              SQLServer::Errors

      ADAPTER_NAME = 'SQLServer'.freeze

      attr_reader :spid

      cattr_accessor :auto_connect, :auto_connect_duration, instance_accessor: false
      cattr_accessor :cs_equality_operator, instance_accessor: false
      cattr_accessor :lowercase_schema_reflection, :showplan_option

      self.cs_equality_operator = 'COLLATE Latin1_General_CS_AS_WS'

      def initialize(connection, logger, pool, config)
        super(connection, logger, pool)
        # AbstractAdapter Responsibility
        @schema_cache = SQLServer::SchemaCache.new self
        @visitor = Arel::Visitors::SQLServer.new self
        @prepared_statements = true
        # Our Responsibility
        @config = config
        @connection_options = config
        connect
        @sqlserver_azure = !!(select_value('SELECT @@version', 'SCHEMA') =~ /Azure/i)
        initialize_dateformatter
        use_database
      end

      # === Abstract Adapter ========================================== #

      def valid_type?(type)
        !native_database_types[type].nil?
      end

      def schema_creation
        SQLServer::SchemaCreation.new self
      end

      def adapter_name
        ADAPTER_NAME
      end

      def supports_migrations?
        true
      end

      def supports_primary_key?
        true
      end

      def supports_count_distinct?
        true
      end

      def supports_ddl_transactions?
        true
      end

      def supports_bulk_alter?
        false
      end

      def supports_index_sort_order?
        true
      end

      def supports_partial_index?
        true
      end

      def supports_explain?
        true
      end

      def disable_referential_integrity
        do_execute "EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'"
        yield
      ensure
        do_execute "EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL'"
      end

      # === Abstract Adapter (Connection Management) ================== #

      def active?
        return false unless @connection
        case @connection_options[:mode]
        when :dblib
          return @connection.active?
        end
        raw_connection_do('SELECT 1')
        true
      rescue *lost_connection_exceptions
        false
      end

      def reconnect!
        super
        disconnect!
        connect
      end

      def disconnect!
        super
        @spid = nil
        case @connection_options[:mode]
        when :dblib
          @connection.close rescue nil
        when :odbc
          @connection.disconnect rescue nil
        end
        @connection = nil
      end

      def reset!
        remove_database_connections_and_rollback {}
      end

      # === Abstract Adapter (Misc Support) =========================== #

      def pk_and_sequence_for(table_name)
        pk = primary_key(table_name)
        pk ? [pk, nil] : nil
      end

      def primary_key(table_name)
        identity_column(table_name).try(:name) || schema_cache.columns(table_name).find(&:is_primary?).try(:name)
      end

      # === SQLServer Specific (DB Reflection) ======================== #

      def sqlserver?
        true
      end

      def sqlserver_azure?
        @sqlserver_azure
      end

      def version
        self.class::VERSION
      end

      def inspect
        "#<#{self.class} version: #{version}, mode: #{@connection_options[:mode]}, azure: #{sqlserver_azure?.inspect}>"
      end

      def auto_connect
        self.class.auto_connect.is_a?(FalseClass) ? false : true
      end

      def auto_connect_duration
        self.class.auto_connect_duration ||= 10
      end


      protected

      # === Abstract Adapter (Misc Support) =========================== #

      def initialize_type_map(m)
        m.register_type              %r{.*},            SQLServer::Type::UnicodeString.new
        # Exact Numerics
        register_class_with_limit m, 'bigint(8)',         SQLServer::Type::BigInteger
        m.alias_type                 'bigint',            'bigint(8)'
        register_class_with_limit m, 'int(4)',            SQLServer::Type::Integer
        m.alias_type                 'integer',           'int(4)'
        m.alias_type                 'int',               'int(4)'
        register_class_with_limit m, 'smallint(2)',       SQLServer::Type::SmallInteger
        m.alias_type                 'smallint',          'smallint(2)'
        register_class_with_limit m, 'tinyint(1)',        SQLServer::Type::TinyInteger
        m.alias_type                 'tinyint',           'tinyint(1)'
        m.register_type              'bit',               SQLServer::Type::Boolean.new
        m.register_type              %r{\Adecimal}i do |sql_type|
          scale = extract_scale(sql_type)
          precision = extract_precision(sql_type)
          SQLServer::Type::Decimal.new precision: precision, scale: scale
        end
        m.alias_type                 %r{\Anumeric}i,      'decimal'
        m.register_type              'money',             SQLServer::Type::Money.new
        m.register_type              'smallmoney',        SQLServer::Type::SmallMoney.new
        # Approximate Numerics
        m.register_type              'float',             SQLServer::Type::Float.new
        m.register_type              'real',              SQLServer::Type::Real.new
        # Date and Time
        m.register_type              'date',              SQLServer::Type::Date.new
        m.register_type              'datetime',          SQLServer::Type::DateTime.new
        m.register_type              'smalldatetime',     SQLServer::Type::SmallDateTime.new
        m.register_type              %r{\Atime}i do |sql_type|
          scale = extract_scale(sql_type)
          precision = extract_precision(sql_type)
          SQLServer::Type::Time.new precision: precision
        end
        # Character Strings
        register_class_with_limit m, %r{\Achar}i,         SQLServer::Type::Char
        register_class_with_limit m, %r{\Avarchar}i,      SQLServer::Type::Varchar
        m.register_type              'varchar(max)',      SQLServer::Type::VarcharMax.new
        m.register_type              'text',              SQLServer::Type::Text.new
        # Unicode Character Strings
        register_class_with_limit m, %r{\Anchar}i,        SQLServer::Type::UnicodeChar
        register_class_with_limit m, %r{\Anvarchar}i,     SQLServer::Type::UnicodeVarchar
        m.alias_type                 'string',            'nvarchar(4000)'
        m.register_type              'nvarchar(max)',     SQLServer::Type::UnicodeVarcharMax.new
        m.register_type              'ntext',             SQLServer::Type::UnicodeText.new
        # Binary Strings
        register_class_with_limit m, %r{\Abinary}i,       SQLServer::Type::Binary
        register_class_with_limit m, %r{\Avarbinary}i,    SQLServer::Type::Varbinary
        m.register_type              'varbinary(max)',    SQLServer::Type::VarbinaryMax.new
        # Other Data Types
        m.register_type              'uniqueidentifier',  SQLServer::Type::Uuid.new
      end

      def translate_exception(e, message)
        case message
        when /(cannot insert duplicate key .* with unique index) | (violation of unique key constraint)/i
          RecordNotUnique.new(message, e)
        when /conflicted with the foreign key constraint/i
          InvalidForeignKey.new(message, e)
        when /has been chosen as the deadlock victim/i
          DeadlockVictim.new(message, e)
        when *lost_connection_messages
          LostConnection.new(message, e)
        else
          super
        end
      end

      # === SQLServer Specific (Connection Management) ================ #

      def connect
        config = @connection_options
        @connection = case config[:mode]
                      when :dblib
                        dblib_connect(config)
                      when :odbc
                        odbc_connect(config)
                      end
        @spid = _raw_select('SELECT @@SPID', fetch: :rows).first.first
        configure_connection
      rescue
        raise unless @auto_connecting
      end

      def dblib_connect(config)
        TinyTds::Client.new(
          dataserver: config[:dataserver],
          host: config[:host],
          port: config[:port],
          username: config[:username],
          password: config[:password],
          database: config[:database],
          tds_version: config[:tds_version],
          appname: config_appname(config),
          login_timeout: config_login_timeout(config),
          timeout: config_timeout(config),
          encoding:  config_encoding(config),
          azure: config[:azure]
        ).tap do |client|
          if config[:azure]
            client.execute('SET ANSI_NULLS ON').do
            client.execute('SET CURSOR_CLOSE_ON_COMMIT OFF').do
            client.execute('SET ANSI_NULL_DFLT_ON ON').do
            client.execute('SET IMPLICIT_TRANSACTIONS OFF').do
            client.execute('SET ANSI_PADDING ON').do
            client.execute('SET QUOTED_IDENTIFIER ON')
            client.execute('SET ANSI_WARNINGS ON').do
          else
            client.execute('SET ANSI_DEFAULTS ON').do
            client.execute('SET CURSOR_CLOSE_ON_COMMIT OFF').do
            client.execute('SET IMPLICIT_TRANSACTIONS OFF').do
          end
          client.execute('SET TEXTSIZE 2147483647').do
          client.execute('SET CONCAT_NULL_YIELDS_NULL ON').do
        end
      end

      def odbc_connect(config)
        if config[:dsn].include?(';')
          driver = ODBC::Driver.new.tap do |d|
            d.name = config[:dsn_name] || 'Driver1'
            d.attrs = config[:dsn].split(';').map { |atr| atr.split('=') }.reject { |kv| kv.size != 2 }.reduce({}) { |a, e| k, v = e ; a[k] = v ; a }
          end
          ODBC::Database.new.drvconnect(driver)
        else
          ODBC.connect config[:dsn], config[:username], config[:password]
        end.tap do |c|
          begin
            c.use_time = true
            c.use_utc = ActiveRecord::Base.default_timezone == :utc
          rescue Exception
            warn 'Ruby ODBC v0.99992 or higher is required.'
          end
        end
      end

      def config_appname(config)
        config[:appname] || configure_application_name || Rails.application.class.name.split('::').first rescue nil
      end

      def config_login_timeout(config)
        config[:login_timeout].present? ? config[:login_timeout].to_i : nil
      end

      def config_timeout(config)
        config[:timeout].present? ? config[:timeout].to_i / 1000 : nil
      end

      def config_encoding(config)
        config[:encoding].present? ? config[:encoding] : nil
      end

      def configure_connection ; end

      def configure_application_name ; end

      def initialize_dateformatter
        @database_dateformat = user_options_dateformat
        a, b, c = @database_dateformat.each_char.to_a
        [a, b, c].each { |f| f.upcase! if f == 'y' }
        dateformat = "%#{a}-%#{b}-%#{c}"
        ::Date::DATE_FORMATS[:_sqlserver_dateformat] = dateformat
        ::Time::DATE_FORMATS[:_sqlserver_dateformat] = dateformat
      end

      def remove_database_connections_and_rollback(database = nil)
        name = SQLServer::Utils.extract_identifiers(database || current_database)
        do_execute "ALTER DATABASE #{name} SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
        begin
          yield
        ensure
          do_execute "ALTER DATABASE #{name} SET MULTI_USER"
        end if block_given?
      end

      def with_sqlserver_error_handling
        yield
      rescue Exception => e
        case translate_exception(e, e.message)
        when LostConnection then retry if auto_reconnected?
        end
        raise
      end

      def disable_auto_reconnect
        old_auto_connect, self.class.auto_connect = self.class.auto_connect, false
        yield
      ensure
        self.class.auto_connect = old_auto_connect
      end

      def auto_reconnected?
        return false unless auto_connect
        @auto_connecting = true
        count = 0
        while count <= (auto_connect_duration / 2)
          disconnect!
          reconnect!
          ActiveRecord::Base.did_retry_sqlserver_connection(self, count)
          return true if active?
          sleep 2**count
          count += 1
        end
        ActiveRecord::Base.did_lose_sqlserver_connection(self)
        false
      ensure
        @auto_connecting = false
      end

    end
  end
end
