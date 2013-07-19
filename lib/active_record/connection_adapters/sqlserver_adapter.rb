require 'base64'
require 'arel/visitors/sqlserver'
require 'active_record'
require 'active_record/base'
require 'active_support/concern'
require 'active_support/core_ext/string'
require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/sqlserver/core_ext/active_record'
require 'active_record/connection_adapters/sqlserver/core_ext/database_statements'
require 'active_record/connection_adapters/sqlserver/core_ext/explain'
require 'active_record/connection_adapters/sqlserver/core_ext/relation'
require 'active_record/connection_adapters/sqlserver/database_limits'
require 'active_record/connection_adapters/sqlserver/database_statements'
require 'active_record/connection_adapters/sqlserver/errors'
require 'active_record/connection_adapters/sqlserver/schema_cache'
require 'active_record/connection_adapters/sqlserver/schema_statements'
require 'active_record/connection_adapters/sqlserver/showplan'
require 'active_record/connection_adapters/sqlserver/quoting'
require 'active_record/connection_adapters/sqlserver/utils'
require 'active_record/connection_adapters/sqlserver/database_tasks'


module ActiveRecord
  
  class Base
    
    def self.sqlserver_connection(config) #:nodoc:
      config = config.symbolize_keys
      config.reverse_merge! :mode => :dblib
      mode = config[:mode].to_s.downcase.underscore.to_sym
      case mode
      when :dblib
        require 'tiny_tds'
      when :odbc
        raise ArgumentError, 'Missing :dsn configuration.' unless config.has_key?(:dsn)
        require 'odbc'
        require 'active_record/connection_adapters/sqlserver/core_ext/odbc'
      else
        raise ArgumentError, "Unknown connection mode in #{config.inspect}."
      end
      ConnectionAdapters::SQLServerAdapter.new(nil, logger, nil, config.merge(:mode=>mode))
    end
    
    protected
    
    def self.did_retry_sqlserver_connection(connection,count)
      logger.info "CONNECTION RETRY: #{connection.class.name} retry ##{count}."
    end
    
    def self.did_lose_sqlserver_connection(connection)
      logger.info "CONNECTION LOST: #{connection.class.name}"
    end
    
  end

  module Tasks
    module DatabaseTasks
      register_task(/sqlserver/,ActiveRecord::Tasks::SQLServerDatabaseTasks)
    end
  end
  
  module ConnectionAdapters
    
    class SQLServerColumn < Column

      def initialize(name, default, sql_type = nil, null = true, sqlserver_options = {})
        @sqlserver_options = sqlserver_options.symbolize_keys
        super(name, default, sql_type, null)
        @primary = @sqlserver_options[:is_identity] || @sqlserver_options[:is_primary]
      end
      
      class << self
        
        def string_to_binary(value)
         "0x#{value.unpack("H*")[0]}"
        end
        
        def binary_to_string(value)
          value =~ /[^[:xdigit:]]/ ? value : [value].pack('H*')
        end
        
      end
      
      def is_identity?
        @sqlserver_options[:is_identity]
      end
      
      def is_primary?
        @sqlserver_options[:is_primary]
      end
      
      def is_utf8?
        !!(@sql_type =~ /nvarchar|ntext|nchar/i)
      end
      
      def is_integer?
        !!(@sql_type =~ /int/i)
      end
      
      def is_real?
        !!(@sql_type =~ /real/i)
      end
      
      def sql_type_for_statement
        if is_integer? || is_real?
          sql_type.sub(/\((\d+)?\)/,'')
        else
          sql_type
        end
      end
      
      def default_function
        @sqlserver_options[:default_function]
      end
      
      def table_name
        @sqlserver_options[:table_name]
      end
      
      def table_klass
        @table_klass ||= begin
          table_name.classify.constantize
        rescue StandardError, NameError, LoadError
          nil
        end
        (@table_klass && @table_klass < ActiveRecord::Base) ? @table_klass : nil
      end
      
      def database_year
        @sqlserver_options[:database_year]
      end
      
      
      private
      
      def extract_limit(sql_type)
        case sql_type
        when /^smallint/i
          2
        when /^int/i
          4
        when /^bigint/i
          8
        when /\(max\)/, /decimal/, /numeric/
          nil
        else
          super
        end
      end
      
      def simplified_type(field_type)
        case field_type
          when /real/i              then :float
          when /money/i             then :decimal
          when /image/i             then :binary
          when /bit/i               then :boolean
          when /uniqueidentifier/i  then :string
          when /datetime/i          then simplified_datetime
          when /varchar\(max\)/     then :text
          when /timestamp/          then :binary
          else super
        end
      end
      
      def simplified_datetime
        if database_year >= 2008
          :datetime
        elsif table_klass && table_klass.coerced_sqlserver_date_columns.include?(name)
          :date
        elsif table_klass && table_klass.coerced_sqlserver_time_columns.include?(name)
          :time
        else
          :datetime
        end
      end
      
    end #class SQLServerColumn
    
    class SQLServerAdapter < AbstractAdapter
      
      include Sqlserver::Quoting
      include Sqlserver::DatabaseStatements
      include Sqlserver::Showplan
      include Sqlserver::SchemaStatements
      include Sqlserver::DatabaseLimits
      include Sqlserver::Errors
      
      VERSION                     = File.read(File.expand_path("../../../../VERSION",__FILE__)).strip
      ADAPTER_NAME                = 'SQLServer'.freeze
      DATABASE_VERSION_REGEXP     = /Microsoft SQL Server\s+"?(\d{4}|\w+)"?/
      SUPPORTED_VERSIONS          = [2005,2008,2010,2011,2012]
      
      attr_reader :database_version, :database_year, :spid, :product_level, :product_version, :edition
      
      cattr_accessor :native_text_database_type, :native_binary_database_type, :native_string_database_type,
                     :enable_default_unicode_types, :auto_connect, :retry_deadlock_victim,
                     :cs_equality_operator, :lowercase_schema_reflection, :auto_connect_duration,
                     :showplan_option
      
      self.enable_default_unicode_types = true
      
      
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
                           if @database_version =~ /Microsoft SQL Azure/i
                             @sqlserver_azure = true
                             @database_version.match(/\s(\d{4})\s/)[1].to_i
                           else
                             year = DATABASE_VERSION_REGEXP.match(@database_version)[1]
                             year == "Denali" ? 2011 : year.to_i
                           end
                         rescue
                           0
                         end
        @product_level    = select_value "SELECT CAST(SERVERPROPERTY('productlevel') AS VARCHAR(128))", 'SCHEMA'
        @product_version  = select_value "SELECT CAST(SERVERPROPERTY('productversion') AS VARCHAR(128))", 'SCHEMA'
        @edition          = select_value "SELECT CAST(SERVERPROPERTY('edition') AS VARCHAR(128))", 'SCHEMA'
        initialize_dateformatter
        use_database
        unless SUPPORTED_VERSIONS.include?(@database_year)
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
        raw_connection_do("SELECT 1")
        true
      rescue *lost_connection_exceptions
        false
      end

      def reconnect!
        disconnect!
        connect
        active?
      end

      def disconnect!
        @spid = nil
        case @connection_options[:mode]
        when :dblib
          @connection.close rescue nil
        when :odbc
          @connection.disconnect rescue nil
        end
      end
      
      def reset!
        remove_database_connections_and_rollback { }
      end
      
      # === Abstract Adapter (Misc Support) =========================== #
      
      def pk_and_sequence_for(table_name)
        idcol = identity_column(table_name)
        idcol ? [idcol.name,nil] : nil
      end

      def primary_key(table_name)
        identity_column(table_name).try(:name) || schema_cache.columns[table_name].detect(&:is_primary?).try(:name)
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
      
      def retry_deadlock_victim
        @@retry_deadlock_victim.is_a?(FalseClass) ? false : true
      end
      alias :retry_deadlock_victim? :retry_deadlock_victim
      
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
        when /cannot insert duplicate key .* with unique index/i
          RecordNotUnique.new(message,e)
        when /conflicted with the foreign key constraint/i
          InvalidForeignKey.new(message,e)
        when /has been chosen as the deadlock victim/i
          DeadlockVictim.new(message,e)
        when *lost_connection_messages
          LostConnection.new(message,e)
        else
          super
        end
      end
      
      # === SQLServer Specific (Connection Management) ================ #
      
      def connect
        config = @connection_options
        @connection = case config[:mode]
                      when :dblib
                        appname = config[:appname] || configure_application_name || Rails.application.class.name.split('::').first rescue nil
                        login_timeout = config[:login_timeout].present? ? config[:login_timeout].to_i : nil
                        timeout = config[:timeout].present? ? config[:timeout].to_i/1000 : nil
                        encoding = config[:encoding].present? ? config[:encoding] : nil
                        TinyTds::Client.new({ 
                          :dataserver    => config[:dataserver],
                          :host          => config[:host],
                          :port          => config[:port],
                          :username      => config[:username],
                          :password      => config[:password],
                          :database      => config[:database],
                          :appname       => appname,
                          :login_timeout => login_timeout,
                          :timeout       => timeout,
                          :encoding      => encoding,
                          :azure         => config[:azure]
                        }).tap do |client|
                          if config[:azure]
                            client.execute("SET ANSI_NULLS ON").do
                            client.execute("SET CURSOR_CLOSE_ON_COMMIT OFF").do
                            client.execute("SET ANSI_NULL_DFLT_ON ON").do
                            client.execute("SET IMPLICIT_TRANSACTIONS OFF").do
                            client.execute("SET ANSI_PADDING ON").do
                            client.execute("SET QUOTED_IDENTIFIER ON")
                            client.execute("SET ANSI_WARNINGS ON").do
                          else
                            client.execute("SET ANSI_DEFAULTS ON").do
                            client.execute("SET CURSOR_CLOSE_ON_COMMIT OFF").do
                            client.execute("SET IMPLICIT_TRANSACTIONS OFF").do
                          end
                          client.execute("SET TEXTSIZE 2147483647").do
                        end
                      when :odbc
                        if config[:dsn].include?(';')
                          driver = ODBC::Driver.new.tap do |d|
                            d.name = config[:dsn_name] || 'Driver1'
                            d.attrs = config[:dsn].split(';').map{ |atr| atr.split('=') }.reject{ |kv| kv.size != 2 }.inject({}){ |h,kv| k,v = kv ; h[k] = v ; h }
                          end
                          ODBC::Database.new.drvconnect(driver)
                        else
                          ODBC.connect config[:dsn], config[:username], config[:password]
                        end.tap do |c|  
                          begin
                            c.use_time = true
                            c.use_utc = ActiveRecord::Base.default_timezone == :utc
                          rescue Exception => e
                            warn "Ruby ODBC v0.99992 or higher is required."
                          end
                        end
                      end
        @spid = _raw_select("SELECT @@SPID", :fetch => :rows).first.first
        configure_connection
      rescue
        raise unless @auto_connecting
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
        [a,b,c].each { |f| f.upcase! if f == 'y' }
        dateformat = "%#{a}-%#{b}-%#{c}"
        ::Date::DATE_FORMATS[:_sqlserver_dateformat] = dateformat
        ::Time::DATE_FORMATS[:_sqlserver_dateformat] = dateformat
      end
      
      def remove_database_connections_and_rollback(database=nil)
        database ||= current_database
        do_execute "ALTER DATABASE #{quote_table_name(database)} SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
        begin
          yield
        ensure
          do_execute "ALTER DATABASE #{quote_table_name(database)} SET MULTI_USER"
        end if block_given?
      end
      
      def with_sqlserver_error_handling
        begin
          yield
        rescue Exception => e
          case translate_exception(e,e.message)
            when LostConnection; retry if auto_reconnected?
            when DeadlockVictim; retry if retry_deadlock_victim? && open_transactions == 0
          end
          raise
        end
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
          sleep 2** count
          ActiveRecord::Base.did_retry_sqlserver_connection(self,count)
          return true if reconnect!
          count += 1
        end
        ActiveRecord::Base.did_lose_sqlserver_connection(self)
        false
      ensure
        @auto_connecting = false
      end
            
    end #class SQLServerAdapter < AbstractAdapter
    
  end #module ConnectionAdapters
  
end #module ActiveRecord

