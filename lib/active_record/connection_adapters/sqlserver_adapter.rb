require 'active_record'
require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/sqlserver_adapter/core_ext/active_record'
require 'active_record/connection_adapters/sqlserver/database_limits'
require 'active_record/connection_adapters/sqlserver/database_statements'
require 'active_record/connection_adapters/sqlserver/quoting'
require 'active_support/core_ext/kernel/requires'
require 'base64'

module ActiveRecord
  
  class Base
    
    def self.sqlserver_connection(config) #:nodoc:
      config = config.dup.symbolize_keys!
      config.reverse_merge! :mode => :odbc, :host => 'localhost', :username => 'sa', :password => ''
      mode = config[:mode].to_s.downcase.underscore.to_sym
      case mode
      when :odbc
        require_library_or_gem 'odbc' unless defined?(ODBC)
        require 'active_record/connection_adapters/sqlserver_adapter/core_ext/odbc'
        raise ArgumentError, 'Missing :dsn configuration.' unless config.has_key?(:dsn)
      when :adonet
        require 'System.Data'
        raise ArgumentError, 'Missing :database configuration.' unless config.has_key?(:database)
      when :ado
        raise NotImplementedError, 'Please use version 2.3.1 of the adapter for ADO connections. Future versions may support ADO.NET.'
        raise ArgumentError, 'Missing :database configuration.' unless config.has_key?(:database)
      else
        raise ArgumentError, "Unknown connection mode in #{config.inspect}."
      end
      ConnectionAdapters::SQLServerAdapter.new(logger,config.merge(:mode=>mode))
    end
    
    protected
    
    def self.did_retry_sqlserver_connection(connection,count)
      logger.info "CONNECTION RETRY: #{connection.class.name} retry ##{count}."
    end
    
    def self.did_lose_sqlserver_connection(connection)
      logger.info "CONNECTION LOST: #{connection.class.name}"
    end
    
  end
  
  module ConnectionAdapters
    
    class SQLServerColumn < Column
            
      def initialize(name, default, sql_type = nil, null = true, sqlserver_options = {})
        @sqlserver_options = sqlserver_options
        super(name, default, sql_type, null)
      end
      
      class << self
        
        def string_to_utf8_encoding(value)
          value.force_encoding('UTF-8') rescue value
        end
        
        def string_to_binary(value)
          value = value.dup.force_encoding(Encoding::BINARY) if value.respond_to?(:force_encoding)
         "0x#{value.unpack("H*")[0]}"
        end
        
        def binary_to_string(value)
          value = value.dup.force_encoding(Encoding::BINARY) if value.respond_to?(:force_encoding)
          value =~ /[^[:xdigit:]]/ ? value : [value].pack('H*')
        end
        
      end
      
      def type_cast(value)
        if value && type == :string && is_utf8?
          self.class.string_to_utf8_encoding(value)
        else
          super
        end
      end
      
      def type_cast_code(var_name)
        if type == :string && is_utf8?
          "#{self.class.name}.string_to_utf8_encoding(#{var_name})"
        else
          super
        end
      end
      
      def is_identity?
        @sqlserver_options[:is_identity]
      end
      
      def is_special?
        # TODO: Not sure if these should be added: varbinary(max), nchar, nvarchar(max)
        sql_type =~ /^text|ntext|image$/
      end
      
      def is_utf8?
        sql_type =~ /nvarchar|ntext|nchar/i
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
      
    end #SQLServerColumn
    
    class SQLServerAdapter < AbstractAdapter
      
      include Sqlserver::Quoting
      include Sqlserver::DatabaseStatements
      include Sqlserver::DatabaseLimits
      
      ADAPTER_NAME                = 'SQLServer'.freeze
      VERSION                     = '3.0.0.beta1'.freeze
      DATABASE_VERSION_REGEXP     = /Microsoft SQL Server\s+(\d{4})/
      SUPPORTED_VERSIONS          = [2000,2005,2008].freeze
      LIMITABLE_TYPES             = ['string','integer','float','char','nchar','varchar','nvarchar'].freeze
      LOST_CONNECTION_EXCEPTIONS  = {
        :odbc   => ['ODBC::Error'],
        :adonet => ['TypeError','System::Data::SqlClient::SqlException']
      }
      LOST_CONNECTION_MESSAGES    = {
        :odbc   => [/link failure/, /server failed/, /connection was already closed/, /invalid handle/i],
        :adonet => [/current state is closed/, /network-related/]
      }
      
      cattr_accessor :native_text_database_type, :native_binary_database_type, :native_string_database_type,
                     :log_info_schema_queries, :enable_default_unicode_types, :auto_connect
      
      class << self
        
        def type_limitable?(type)
          LIMITABLE_TYPES.include?(type.to_s)
        end
        
      end
      
      def initialize(logger,config)
        @connection_options = config
        connect
        super(raw_connection, logger)
        initialize_sqlserver_caches
        use_database
        unless SUPPORTED_VERSIONS.include?(database_year)
          raise NotImplementedError, "Currently, only #{SUPPORTED_VERSIONS.to_sentence} are supported."
        end
      end
      
      # ABSTRACT ADAPTER =========================================#
      
      def adapter_name
        ADAPTER_NAME
      end
      
      def supports_migrations?
        true
      end
      
      def supports_primary_key?
        true
      end
      
      def supports_ddl_transactions?
        true
      end
      
      def supports_savepoints?
        true
      end
      
      def database_version
        @database_version ||= info_schema_query { select_value('SELECT @@version') }
      end
      
      def database_year
        DATABASE_VERSION_REGEXP.match(database_version)[1].to_i
      end
      
      def sqlserver?
        true
      end
      
      def sqlserver_2000?
        database_year == 2000
      end
      
      def sqlserver_2005?
        database_year == 2005
      end
      
      def sqlserver_2008?
        database_year == 2008
      end
      
      def version
        self.class::VERSION
      end
      
      def inspect
        "#<#{self.class} version: #{version}, year: #{database_year}, connection_options: #{@connection_options.inspect}>"
      end
      
      def auto_connect
        @@auto_connect.is_a?(FalseClass) ? false : true
      end
      
      def native_string_database_type
        @@native_string_database_type || (enable_default_unicode_types ? 'nvarchar' : 'varchar') 
      end
      
      def native_text_database_type
        @@native_text_database_type || 
        if sqlserver_2005? || sqlserver_2008?
          enable_default_unicode_types ? 'nvarchar(max)' : 'varchar(max)'
        else
          enable_default_unicode_types ? 'ntext' : 'text'
        end
      end
      
      def native_time_database_type
        sqlserver_2008? ? 'time' : 'datetime'
      end
      
      def native_date_database_type
        sqlserver_2008? ? 'date' : 'datetime'
      end
      
      def native_binary_database_type
        @@native_binary_database_type || ((sqlserver_2005? || sqlserver_2008?) ? 'varbinary(max)' : 'image')
      end
      
      # REFERENTIAL INTEGRITY ====================================#
      
      def disable_referential_integrity
        do_execute "EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'"
        yield
      ensure
        do_execute "EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL'"
      end
      
      # CONNECTION MANAGEMENT ====================================#
      
      def active?
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
        case connection_mode
        when :odbc
          raw_connection.disconnect rescue nil
        else :adonet
          raw_connection.close rescue nil
        end
      end
      
      # SCHEMA STATEMENTS ========================================#
      
      def native_database_types
        {
          :primary_key  => "int NOT NULL IDENTITY(1,1) PRIMARY KEY",
          :string       => { :name => native_string_database_type, :limit => 255  },
          :text         => { :name => native_text_database_type },
          :integer      => { :name => "int", :limit => 4 },
          :float        => { :name => "float", :limit => 8 },
          :decimal      => { :name => "decimal" },
          :datetime     => { :name => "datetime" },
          :timestamp    => { :name => "datetime" },
          :time         => { :name => native_time_database_type },
          :date         => { :name => native_date_database_type },
          :binary       => { :name => native_binary_database_type },
          :boolean      => { :name => "bit"},
          # These are custom types that may move somewhere else for good schema_dumper.rb hacking to output them.
          :char         => { :name => 'char' },
          :varchar_max  => { :name => 'varchar(max)' },
          :nchar        => { :name => "nchar" },
          :nvarchar     => { :name => "nvarchar", :limit => 255 },
          :nvarchar_max => { :name => "nvarchar(max)" },
          :ntext        => { :name => "ntext" }
        }
      end
      
      def tables(name = nil)
        info_schema_query do
          select_values "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME <> 'dtproperties'"
        end
      end
      
      def views(name = nil)
        @sqlserver_views_cache ||= 
          info_schema_query { select_values("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME NOT IN ('sysconstraints','syssegments')") }
      end
      
      def view_information(table_name)
        table_name = unqualify_table_name(table_name)
        @sqlserver_view_information_cache[table_name] ||= begin
          view_info = info_schema_query { select_one("SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = '#{table_name}'") }
          if view_info
            if view_info['VIEW_DEFINITION'].blank? || view_info['VIEW_DEFINITION'].length == 4000
              view_info['VIEW_DEFINITION'] = info_schema_query { select_values("EXEC sp_helptext #{table_name}").join }
            end
          end
          view_info
        end
      end
      
      def view_table_name(table_name)
        view_info = view_information(table_name)
        view_info ? get_table_name(view_info['VIEW_DEFINITION']) : table_name
      end
      
      def table_exists?(table_name)
        super || tables.include?(unqualify_table_name(table_name)) || views.include?(table_name.to_s)
      end
      
      def indexes(table_name, name = nil)
        unquoted_table_name = unqualify_table_name(table_name)
        select("EXEC sp_helpindex #{quote_table_name(unquoted_table_name)}",name).inject([]) do |indexes,index|
          if index['index_description'] =~ /primary key/
            indexes
          else
            name    = index['index_name']
            unique  = index['index_description'] =~ /unique/
            columns = index['index_keys'].split(',').map do |column|
              column.strip!
              column.gsub! '(-)', '' if column.ends_with?('(-)')
              column
            end
            indexes << IndexDefinition.new(table_name, name, unique, columns)
          end
        end
      end
      
      def columns(table_name, name = nil)
        return [] if table_name.blank?
        cache_key = unqualify_table_name(table_name)
        @sqlserver_columns_cache[cache_key] ||= column_definitions(table_name).collect do |ci|
          sqlserver_options = ci.except(:name,:default_value,:type,:null).merge(:database_year=>database_year)
          SQLServerColumn.new ci[:name], ci[:default_value], ci[:type], ci[:null], sqlserver_options
        end
      end
      
      def create_table(table_name, options = {})
        super
        remove_sqlserver_columns_cache_for(table_name)
      end
      
      def rename_table(table_name, new_name)
        do_execute "EXEC sp_rename '#{table_name}', '#{new_name}'"
      end
      
      def drop_table(table_name, options = {})
        super
        remove_sqlserver_columns_cache_for(table_name)
      end
      
      def add_column(table_name, column_name, type, options = {})
        super
        remove_sqlserver_columns_cache_for(table_name)
      end
      
      def remove_column(table_name, *column_names)
        column_names.flatten.each do |column_name|
          remove_check_constraints(table_name, column_name)
          remove_default_constraint(table_name, column_name)
          remove_indexes(table_name, column_name)
          do_execute "ALTER TABLE #{quote_table_name(table_name)} DROP COLUMN #{quote_column_name(column_name)}"
        end
        remove_sqlserver_columns_cache_for(table_name)
      end
      
      def change_column(table_name, column_name, type, options = {})
        sql_commands = []
        column_object = columns(table_name).detect { |c| c.name.to_s == column_name.to_s }
        change_column_sql = "ALTER TABLE #{quote_table_name(table_name)} ALTER COLUMN #{quote_column_name(column_name)} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
        change_column_sql << " NOT NULL" if options[:null] == false
        sql_commands << change_column_sql
        if options_include_default?(options) || (column_object && column_object.type != type.to_sym)
         	remove_default_constraint(table_name,column_name)
        end
        if options_include_default?(options)
          remove_sqlserver_columns_cache_for(table_name)
          sql_commands << "ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{default_name(table_name,column_name)} DEFAULT #{quote(options[:default])} FOR #{quote_column_name(column_name)}"
        end
        sql_commands.each { |c| do_execute(c) }
        remove_sqlserver_columns_cache_for(table_name)
      end
      
      def change_column_default(table_name, column_name, default)
        remove_default_constraint(table_name, column_name)
        do_execute "ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{default_name(table_name, column_name)} DEFAULT #{quote(default)} FOR #{quote_column_name(column_name)}"
        remove_sqlserver_columns_cache_for(table_name)
      end
      
      def rename_column(table_name, column_name, new_column_name)
        column_for(table_name,column_name)
        do_execute "EXEC sp_rename '#{table_name}.#{column_name}', '#{new_column_name}', 'COLUMN'"
        remove_sqlserver_columns_cache_for(table_name)
      end
      
      def remove_index(table_name, options = {})
        do_execute "DROP INDEX #{table_name}.#{quote_column_name(index_name(table_name, options))}" rescue nil
      end
      
      def type_to_sql(type, limit = nil, precision = nil, scale = nil)
        limit = nil unless self.class.type_limitable?(type)
        case type.to_s
        when 'integer'
          case limit
            when 1..2       then  'smallint'
            when 3..4, nil  then  'integer'
            when 5..8       then  'bigint'
            else raise(ActiveRecordError, "No integer type has byte size #{limit}. Use a numeric with precision 0 instead.")
          end
        else
          super
        end
      end
      
      def add_order_by_for_association_limiting!(sql, options)
        # Disertation http://gist.github.com/24073
        # Information http://weblogs.sqlteam.com/jeffs/archive/2007/12/13/select-distinct-order-by-error.aspx
        return sql if options[:order].blank?
        columns = sql.match(/SELECT\s+DISTINCT(.*?)FROM/)[1].strip
        sql.sub!(/SELECT\s+DISTINCT/,'SELECT')
        sql << "GROUP BY #{columns} ORDER BY #{order_to_min_set(options[:order])}"
      end
      
      def change_column_null(table_name, column_name, null, default = nil)
        column = column_for(table_name,column_name)
        unless null || default.nil?
          do_execute("UPDATE #{quote_table_name(table_name)} SET #{quote_column_name(column_name)}=#{quote(default)} WHERE #{quote_column_name(column_name)} IS NULL")
        end
        sql = "ALTER TABLE #{table_name} ALTER COLUMN #{quote_column_name(column_name)} #{type_to_sql column.type, column.limit, column.precision, column.scale}"
        sql << " NOT NULL" unless null
        do_execute sql
      end
      
      def pk_and_sequence_for(table_name)
        idcol = identity_column(table_name)
        idcol ? [idcol.name,nil] : nil
      end
      
      def primary_key(table_name)
        identity_column(table_name).try(:name)
      end
      
      # RAKE UTILITY METHODS =====================================#
      
      def recreate_database
        remove_database_connections_and_rollback do
          do_execute "EXEC sp_MSforeachtable 'DROP TABLE ?'"
        end
      end
      
      def recreate_database!(database=nil)
        current_db = current_database
        database ||= current_db
        this_db = database.to_s == current_db
        do_execute 'USE master' if this_db
        drop_database(database)
        create_database(database)
      ensure
        use_database(current_db) if this_db
      end
      
      # Remove existing connections and rollback any transactions if we received the message
      # 'Cannot drop the database 'test' because it is currently in use'
      def drop_database(database)
        retry_count = 0
        max_retries = 1
        begin
          do_execute "DROP DATABASE #{quote_table_name(database)}"
        rescue ActiveRecord::StatementInvalid => err
          if err.message =~ /because it is currently in use/i
            raise if retry_count >= max_retries
            retry_count += 1
            remove_database_connections_and_rollback(database)
            retry
          else
            raise
          end
        end
      end

      def create_database(database)
        do_execute "CREATE DATABASE #{quote_table_name(database)}"
      end
      
      def current_database
        select_value 'SELECT DB_NAME()'
      end
      
      def charset
        select_value "SELECT SERVERPROPERTY('SqlCharSetName')"
      end
      
      # This should disconnect all other users and rollback any transactions for SQL 2000 and 2005
      # http://sqlserver2000.databases.aspfaq.com/how-do-i-drop-a-sql-server-database.html
      def remove_database_connections_and_rollback(database=nil)
        database ||= current_database
        do_execute "ALTER DATABASE #{quote_table_name(database)} SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
        begin
          yield
        ensure
          do_execute "ALTER DATABASE #{quote_table_name(database)} SET MULTI_USER"
        end if block_given?
      end
      
      
      
      protected
      
      # CONNECTION MANAGEMENT ====================================#
      
      def connect
        config = @connection_options
        @connection = case connection_mode
                      when :odbc
                        ODBC.connect config[:dsn], config[:username], config[:password]
                      when :adonet
                        System::Data::SqlClient::SqlConnection.new.tap do |connection|
                          connection.connection_string = System::Data::SqlClient::SqlConnectionStringBuilder.new.tap do |cs|
                            if config[:integrated_security]
                              cs.integrated_security = true
                            else
                              cs.user_i_d = config[:username]
                              cs.password = config[:password]
                            end
                            cs.add 'Server', config[:host].to_clr_string
                            cs.initial_catalog = config[:database]
                            cs.multiple_active_result_sets = false
                            cs.pooling = false
                          end.to_s
                          connection.open
                        end
                      end
      rescue
        raise unless @auto_connecting
      end
      
      def connection_mode
        @connection_options[:mode]
      end
      
      def lost_connection_exceptions
        exceptions = LOST_CONNECTION_EXCEPTIONS[connection_mode]
        @lost_connection_exceptions ||= exceptions ? exceptions.map(&:constantize) : []
      end
      
      def lost_connection_messages
        LOST_CONNECTION_MESSAGES[connection_mode]
      end
      
      def with_auto_reconnect
        begin
          yield
        rescue *lost_connection_exceptions => e
          if lost_connection_messages.any? { |lcm| e.message =~ lcm }
            retry if auto_reconnected?
          end
          raise
        end
      end
      
      def auto_reconnected?
        return false unless auto_connect
        @auto_connecting = true
        count = 0
        while count <= 5
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
      
      def raw_connection_run(sql)
        with_auto_reconnect do
          case connection_mode
          when :odbc
            block_given? ? raw_connection.run_block(sql) { |handle| yield(handle) } : raw_connection.run(sql)
          else :adonet
            raw_connection.create_command.tap{ |cmd| cmd.command_text = sql }.execute_reader
          end
        end
      end
      
      def raw_connection_do(sql)
        case connection_mode
        when :odbc
          raw_connection.do(sql)
        else :adonet
          raw_connection.create_command.tap{ |cmd| cmd.command_text = sql }.execute_non_query
        end
      end
      
      def finish_statement_handle(handle)
        case connection_mode
        when :odbc
          handle.drop if handle && handle.respond_to?(:drop) && !handle.finished?
        when :adonet
          handle.close if handle && handle.respond_to?(:close) && !handle.is_closed
          handle.dispose if handle && handle.respond_to?(:dispose)
        end
        handle
      end
      
      # SCHEMA STATEMENTS ========================================#
      
      def remove_check_constraints(table_name, column_name)
        constraints = info_schema_query { select_values("SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = '#{quote_string(table_name)}' and COLUMN_NAME = '#{quote_string(column_name)}'") }
        constraints.each do |constraint|
          do_execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{quote_column_name(constraint)}"
        end
      end
      
      def remove_default_constraint(table_name, column_name)
        select_all("EXEC sp_helpconstraint '#{quote_string(table_name)}','nomsg'").select do |row|
          row['constraint_type'] == "DEFAULT on column #{column_name}"
        end.each do |row|
          do_execute "ALTER TABLE #{quote_table_name(table_name)} DROP CONSTRAINT #{row['constraint_name']}"
        end
      end
      
      def remove_indexes(table_name, column_name)
        indexes(table_name).select{ |index| index.columns.include?(column_name.to_s) }.each do |index|
          remove_index(table_name, {:name => index.name})
        end
      end
      
      def default_name(table_name, column_name)
        "DF_#{table_name}_#{column_name}"
      end
      
      # IDENTITY INSERTS =========================================#
      
      def with_identity_insert_enabled(table_name)
        table_name = quote_table_name(table_name_or_views_table_name(table_name))
        set_identity_insert(table_name, true)
        yield
      ensure
        set_identity_insert(table_name, false)
      end
      
      def set_identity_insert(table_name, enable = true)
        sql = "SET IDENTITY_INSERT #{table_name} #{enable ? 'ON' : 'OFF'}"
        do_execute(sql,'IDENTITY_INSERT')
      rescue Exception => e
        raise ActiveRecordError, "IDENTITY_INSERT could not be turned #{enable ? 'ON' : 'OFF'} for table #{table_name}"
      end
      
      def query_requires_identity_insert?(sql)
        if insert_sql?(sql)
          table_name = get_table_name(sql)
          id_column = identity_column(table_name)
          id_column && sql =~ /^\s*INSERT[^(]+\([^)]*\b(#{id_column.name})\b,?[^)]*\)/i ? quote_table_name(table_name) : false
        else
          false
        end
      end
      
      def identity_column(table_name)
        columns(table_name).detect(&:is_identity?)
      end
      
      def table_name_or_views_table_name(table_name)
        unquoted_table_name = unqualify_table_name(table_name)
        views.include?(unquoted_table_name) ? view_table_name(unquoted_table_name) : unquoted_table_name
      end
      
      # HELPER METHODS ===========================================#
      
      def insert_sql?(sql)
        !(sql =~ /^\s*INSERT/i).nil?
      end
      
      def unqualify_table_name(table_name)
        table_name.to_s.split('.').last.gsub(/[\[\]]/,'')
      end
      
      def unqualify_db_name(table_name)
        table_names = table_name.to_s.split('.')
        table_names.length == 3 ? table_names.first.tr('[]','') : nil
      end
      
      def get_table_name(sql)
        if sql =~ /^\s*insert\s+into\s+([^\(\s]+)\s*|^\s*update\s+([^\(\s]+)\s*/i
          $1 || $2
        elsif sql =~ /from\s+([^\(\s]+)\s*/i
          $1
        else
          nil
        end
      end
      
      def orders_and_dirs_set(order)
        orders = order.sub('ORDER BY','').split(',').map(&:strip).reject(&:blank?)
        orders_dirs = orders.map do |ord|
          dir = nil
          ord.sub!(/\b(asc|desc)$/i) do |match|
            if match
              dir = match.upcase.strip
              ''
            end
          end
          [ord.strip, dir]
        end
      end
      
      def views_real_column_name(table_name,column_name)
        view_definition = view_information(table_name)['VIEW_DEFINITION']
        match_data = view_definition.match(/([\w-]*)\s+as\s+#{column_name}/im)
        match_data ? match_data[1] : column_name
      end
      
      def order_to_min_set(order)
        orders_dirs = orders_and_dirs_set(order)
        orders_dirs.map do |o,d|
          "MIN(#{o}) #{d}".strip
        end.join(', ')
      end
      
      def sql_for_association_limiting?(sql)
        if md = sql.match(/^\s*SELECT(.*)FROM.*GROUP BY.*ORDER BY.*/im)
          select_froms = md[1].split(',')
          select_froms.size == 1 && !select_froms.first.include?('*')
        end
      end
      
      def remove_sqlserver_columns_cache_for(table_name)
        cache_key = unqualify_table_name(table_name)
        @sqlserver_columns_cache[cache_key] = nil
        initialize_sqlserver_caches(false)
      end
      
      def initialize_sqlserver_caches(reset_columns=true)
        @sqlserver_columns_cache = {} if reset_columns
        @sqlserver_views_cache = nil
        @sqlserver_view_information_cache = {}
      end
      
      def column_definitions(table_name)
        db_name = unqualify_db_name(table_name)
        db_name_with_period = "#{db_name}." if db_name
        table_name = unqualify_table_name(table_name)
        sql = %{
          SELECT
          columns.TABLE_NAME as table_name,
          columns.COLUMN_NAME as name,
          columns.DATA_TYPE as type,
          columns.COLUMN_DEFAULT as default_value,
          columns.NUMERIC_SCALE as numeric_scale,
          columns.NUMERIC_PRECISION as numeric_precision,
          CASE
            WHEN columns.DATA_TYPE IN ('nchar','nvarchar') THEN columns.CHARACTER_MAXIMUM_LENGTH
            ELSE COL_LENGTH(columns.TABLE_SCHEMA+'.'+columns.TABLE_NAME, columns.COLUMN_NAME)
          END as length,
          CASE
            WHEN columns.IS_NULLABLE = 'YES' THEN 1
            ELSE NULL
          end as is_nullable,
          CASE
            WHEN COLUMNPROPERTY(OBJECT_ID(columns.TABLE_SCHEMA+'.'+columns.TABLE_NAME), columns.COLUMN_NAME, 'IsIdentity') = 0 THEN NULL
            ELSE 1
          END as is_identity
          FROM #{db_name_with_period}INFORMATION_SCHEMA.COLUMNS columns
          WHERE columns.TABLE_NAME = '#{table_name}'
          ORDER BY columns.ordinal_position
        }.gsub(/[ \t\r\n]+/,' ')
        results = info_schema_query { select(sql,nil,true) }
        results.collect do |ci|
          ci.symbolize_keys!
          ci[:type] = case ci[:type]
                      when /^bit|image|text|ntext|datetime$/
                        ci[:type]
                      when /^numeric|decimal$/i
                        "#{ci[:type]}(#{ci[:numeric_precision]},#{ci[:numeric_scale]})"
                      when /^char|nchar|varchar|nvarchar|varbinary|bigint|int|smallint$/
                        ci[:length].to_i == -1 ? "#{ci[:type]}(max)" : "#{ci[:type]}(#{ci[:length]})"
                      else
                        ci[:type]
                      end
          if ci[:default_value].nil? && views.include?(table_name)
            real_table_name = table_name_or_views_table_name(table_name)
            real_column_name = views_real_column_name(table_name,ci[:name])
            col_default_sql = "SELECT c.COLUMN_DEFAULT FROM #{db_name_with_period}INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = '#{real_table_name}' AND c.COLUMN_NAME = '#{real_column_name}'"
            ci[:default_value] = info_schema_query { select_value(col_default_sql) }
          end
          ci[:default_value] = case ci[:default_value]
                               when nil, '(null)', '(NULL)'
                                 nil
                               else
                                 match_data = ci[:default_value].match(/\A\(+N?'?(.*?)'?\)+\Z/m)
                                 match_data ? match_data[1] : nil
                               end
          ci[:null] = ci[:is_nullable].to_i == 1 ; ci.delete(:is_nullable)
          ci
        end
      end
      
      def column_for(table_name, column_name)
        unless column = columns(table_name).detect { |c| c.name == column_name.to_s }
          raise ActiveRecordError, "No such column: #{table_name}.#{column_name}"
        end
        column
      end
      
      def change_order_direction(order)
        order.split(",").collect {|fragment|
          case fragment
            when  /\bDESC\b/i     then fragment.gsub(/\bDESC\b/i, "ASC")
            when  /\bASC\b/i      then fragment.gsub(/\bASC\b/i, "DESC")
            else                  String.new(fragment).split(',').join(' DESC,') + ' DESC'
          end
        }.join(",")
      end
      
      def special_columns(table_name)
        columns(table_name).select(&:is_special?).map(&:name)
      end
      
      def repair_special_columns(sql)
        special_cols = special_columns(get_table_name(sql))
        for col in special_cols.to_a
          sql.gsub!(/((\.|\s|\()\[?#{col.to_s}\]?)\s?=\s?/, '\1 LIKE ')
          sql.gsub!(/ORDER BY #{col.to_s}/i, '')
        end
        sql
      end
            
    end #class SQLServerAdapter < AbstractAdapter
    
  end #module ConnectionAdapters
  
end #module ActiveRecord

