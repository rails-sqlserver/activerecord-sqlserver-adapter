require 'base64'
require 'arel/arel_sqlserver'
require 'arel/visitors/bind_visitor'
require 'active_record'
require 'active_record/base'
require 'active_support/concern'
require 'active_support/core_ext/string'
require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/sqlserver/core_ext/active_record'
require 'active_record/connection_adapters/sqlserver/core_ext/explain'
require 'active_record/connection_adapters/sqlserver/core_ext/explain_subscriber'
require 'active_record/connection_adapters/sqlserver/core_ext/relation'
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
      include Sqlserver::Quoting
      include Sqlserver::DatabaseStatements
      include Sqlserver::Showplan
      include Sqlserver::SchemaStatements
      include Sqlserver::DatabaseLimits
      include Sqlserver::Errors

      VERSION                     = File.read(File.expand_path('../../../../VERSION', __FILE__)).strip
      ADAPTER_NAME                = 'SQLServer'.freeze
      DATABASE_VERSION_REGEXP     = /Microsoft SQL Server\s+"?(\d{4}|\w+)"?/
      SUPPORTED_VERSIONS          = [2005, 2008, 2010, 2011, 2012]

      attr_reader :database_version, :database_year, :spid, :product_level, :product_version, :edition

      cattr_accessor :native_text_database_type, :native_binary_database_type, :native_string_database_type,
                     :enable_default_unicode_types, :auto_connect, :cs_equality_operator,
                     :lowercase_schema_reflection, :auto_connect_duration, :showplan_option

      self.enable_default_unicode_types = true

      class BindSubstitution < Arel::Visitors::SQLServer # :nodoc:
        include Arel::Visitors::BindVisitor
      end

      def initialize(connection, logger, pool, config)
        super(connection, logger, pool)
        # AbstractAdapter Responsibility
        @schema_cache = Sqlserver::SchemaCache.new self
        @visitor = Arel::Visitors::SQLServer.new self
        # Our Responsibility
        @config = config
        @connection_options = config
        connect
        @database_version = select_value 'SELECT @@version', 'SCHEMA'
        @database_year = begin
                           if @database_version =~ /Azure/i
                             @sqlserver_azure = true
                             @database_version.match(/\s-\s([0-9.]+)/)[1]
                             year = 2012
                           else
                             year = DATABASE_VERSION_REGEXP.match(@database_version)[1]
                             year == 'Denali' ? 2011 : year.to_i
                           end
                         rescue
                           0
                         end
        @product_level    = select_value "SELECT CAST(SERVERPROPERTY('productlevel') AS VARCHAR(128))", 'SCHEMA'
        @product_version  = select_value "SELECT CAST(SERVERPROPERTY('productversion') AS VARCHAR(128))", 'SCHEMA'
        @edition          = select_value "SELECT CAST(SERVERPROPERTY('edition') AS VARCHAR(128))", 'SCHEMA'
        initialize_dateformatter
        use_database
        unless @sqlserver_azure == true || SUPPORTED_VERSIONS.include?(@database_year)
          raise NotImplementedError, "Currently, only #{SUPPORTED_VERSIONS.to_sentence} are supported. We got back #{@database_version}."
        end
      end

      # === Abstract Adapter ========================================== #

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

      def supports_savepoints?
        true
      end

      def supports_index_sort_order?
        true
      end

      def supports_partial_index?
        @database_year >= 2008
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
        reset_transaction
        disconnect!
        connect
        active?
      end

      def disconnect!
        reset_transaction
        @spid = nil
        case @connection_options[:mode]
        when :dblib
          @connection.close rescue nil
        when :odbc
          @connection.disconnect rescue nil
        end
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

      def schema_creation
        Sqlserver::SchemaCreation.new self
      end

      # === SQLServer Specific (DB Reflection) ======================== #

      def sqlserver?
        true
      end

      def sqlserver_2005?
        @database_year == 2005
      end

      def sqlserver_2008?
        @database_year == 2008
      end

      def sqlserver_2011?
        @database_year == 2011
      end

      def sqlserver_2012?
        @database_year == 2012
      end

      def sqlserver_azure?
        @sqlserver_azure
      end

      def version
        self.class::VERSION
      end

      def inspect
        "#<#{self.class} version: #{version}, year: #{@database_year}, product_level: #{@product_level.inspect}, product_version: #{@product_version.inspect}, edition: #{@edition.inspect}, connection_options: #{@connection_options.inspect}>"
      end

      def auto_connect
        @@auto_connect.is_a?(FalseClass) ? false : true
      end

      def auto_connect_duration
        @@auto_connect_duration ||= 10
      end

      def native_string_database_type
        @@native_string_database_type || (enable_default_unicode_types ? 'nvarchar' : 'varchar')
      end

      def native_text_database_type
        @@native_text_database_type || enable_default_unicode_types ? 'nvarchar(max)' : 'varchar(max)'
      end

      def native_time_database_type
        sqlserver_2005? ? 'datetime' : 'time'
      end

      def native_date_database_type
        sqlserver_2005? ? 'datetime' : 'date'
      end

      def native_binary_database_type
        @@native_binary_database_type || 'varbinary(max)'
      end

      def cs_equality_operator
        @@cs_equality_operator || 'COLLATE Latin1_General_CS_AS_WS'
      end

      protected

      # === Abstract Adapter (Misc Support) =========================== #

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
                              appname: appname(config),
                              login_timeout: login_timeout(config),
                              timeout: timeout(config),
                              encoding:  encoding(config),
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

      def appname(config)
        config[:appname] || configure_application_name || Rails.application.class.name.split('::').first rescue nil
      end

      def login_timeout(config)
        config[:login_timeout].present? ? config[:login_timeout].to_i : nil
      end

      def timeout(config)
        config[:timeout].present? ? config[:timeout].to_i / 1000 : nil
      end

      def encoding(config)
        config[:encoding].present? ? config[:encoding] : nil
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

      # Override this method so every connection can be configured to your needs.
      # For example:
      #    raw_connection_do "SET TEXTSIZE #{64.megabytes}"
      #    raw_connection_do "SET CONCAT_NULL_YIELDS_NULL ON"
      def configure_connection
      end

      # Override this method so every connection can have a unique name. Max 30 characters. Used by TinyTDS only.
      # For example:
      #    "myapp_#{$$}_#{Thread.current.object_id}".to(29)
      def configure_application_name
      end

      def initialize_dateformatter
        @database_dateformat = user_options_dateformat
        a, b, c = @database_dateformat.each_char.to_a
        [a, b, c].each { |f| f.upcase! if f == 'y' }
        dateformat = "%#{a}-%#{b}-%#{c}"
        ::Date::DATE_FORMATS[:_sqlserver_dateformat] = dateformat
        ::Time::DATE_FORMATS[:_sqlserver_dateformat] = dateformat
      end

      def remove_database_connections_and_rollback(database = nil)
        database ||= current_database
        do_execute "ALTER DATABASE #{quote_database_name(database)} SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
        begin
          yield
        ensure
          do_execute "ALTER DATABASE #{quote_database_name(database)} SET MULTI_USER"
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
          result = reconnect!
          ActiveRecord::Base.did_retry_sqlserver_connection(self, count)
          return true if result
          sleep 2**count
          count += 1
        end
        ActiveRecord::Base.did_lose_sqlserver_connection(self)
        false
      ensure
        @auto_connecting = false
      end
    end # class SQLServerAdapter < AbstractAdapter
  end # module ConnectionAdapters
end # module ActiveRecord
