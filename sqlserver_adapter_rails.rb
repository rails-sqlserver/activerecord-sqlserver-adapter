require 'active_record/connection_adapters/abstract_adapter'

require 'bigdecimal'
require 'bigdecimal/util'

# sqlserver_adapter.rb -- ActiveRecord adapter for Microsoft SQL Server
#
# Author: Joey Gibson <joey@joeygibson.com>
# Date:   10/14/2004
#
# Modifications: DeLynn Berry <delynnb@megastarfinancial.com>
# Date: 3/22/2005
#
# Modifications (ODBC): Mark Imbriaco <mark.imbriaco@pobox.com>
# Date: 6/26/2005

# Modifications (Migrations): Tom Ward <tom@popdog.net>
# Date: 27/10/2005
#
# Modifications (Numerous fixes as maintainer): Ryan Tomayko <rtomayko@gmail.com>
# Date: Up to July 2006

# Current maintainer: Tom Ward <tom@popdog.net>

module ActiveRecord
  class Base
    def self.sqlserver_connection(config) #:nodoc:
      require_library_or_gem 'dbi' unless self.class.const_defined?(:DBI)
      
      config = config.symbolize_keys

      mode        = config[:mode] ? config[:mode].to_s.upcase : 'ADO'
      username    = config[:username] ? config[:username].to_s : 'sa'
      password    = config[:password] ? config[:password].to_s : ''
      autocommit  = config.key?(:autocommit) ? config[:autocommit] : true
      if mode == "ODBC"
        raise ArgumentError, "Missing DSN. Argument ':dsn' must be set in order for this adapter to work." unless config.has_key?(:dsn)
        dsn       = config[:dsn]
        driver_url = "DBI:ODBC:#{dsn}"
      else
        raise ArgumentError, "Missing Database. Argument ':database' must be set in order for this adapter to work." unless config.has_key?(:database)
        database  = config[:database]
        host      = config[:host] ? config[:host].to_s : 'localhost'
        driver_url = "DBI:ADO:Provider=SQLOLEDB;Data Source=#{host};Initial Catalog=#{database};User Id=#{username};Password=#{password};"
      end
      conn      = DBI.connect(driver_url, username, password)
      conn["AutoCommit"] = autocommit
      ConnectionAdapters::SQLServerAdapter.new(conn, logger, [driver_url, username, password])
    end
   # Overridden to include support for SQL server's lack of = operator on
    # text/ntext/image columns LIKE operator is used instead
    def self.sanitize_sql_hash(attrs)
      conditions = attrs.map do |attr, value|
        col = self.columns.find {|c| c.name == attr}
        if col && col.respond_to?("is_special") && col.is_special
          "#{table_name}.#{connection.quote_column_name(attr)} LIKE ?"
        else
          "#{table_name}.#{connection.quote_column_name(attr)} #{attribute_condition(value)}"
        end
      end.join(' AND ')
      replace_bind_variables(conditions, expand_range_bind_variables(attrs.values))
    end

    # In the case of SQL server, the lock value must follow the FROM clause
    def self.construct_finder_sql(options)
      scope = scope(:find)
      sql  = "SELECT #{(scope && scope[:select]) || options[:select] || '*'} "
      sql << "FROM #{(scope && scope[:from]) || options[:from] || table_name} "
      
      if ActiveRecord::Base.connection.adapter_name == "SQLServer" && !options[:lock].blank? # SQLServer
        add_lock!(sql, options, scope) 
      end
      
      add_joins!(sql, options, scope)
      add_conditions!(sql, options[:conditions], scope)
      
      sql << " GROUP BY #{options[:group]} " if options[:group]

      add_order!(sql, options[:order], scope)
      add_limit!(sql, options, scope)
      add_lock!(sql, options, scope)  unless ActiveRecord::Base.connection.adapter_name == "SQLServer" #  SQLServer
      #      $log.debug "database_helper: construct_finder_sql:  sql at end:  #{sql.inspect}"
      sql
    end 


  end # class Base

  module ConnectionAdapters
    class SQLServerColumn < Column# :nodoc:
      attr_reader :identity, :is_special

      def initialize(name, default, sql_type = nil, identity = false, null = true) # TODO: check ok to remove scale_value = 0
        super(name, default, sql_type, null)
        @identity = identity
        @is_special = sql_type =~ /text|ntext|image/i
        # TODO: check ok to remove @scale = scale_value
        # SQL Server only supports limits on *char and float types
        @limit = nil unless @type == :float or @type == :string
      end

      def simplified_type(field_type)
        case field_type
          when /money/i             then :decimal
          when /image/i             then :binary
          when /bit/i               then :boolean
          when /uniqueidentifier/i  then :string
          else super
        end
      end

      def type_cast(value)
        return nil if value.nil?
        case type
        when :datetime  then cast_to_datetime(value)
        when :timestamp then cast_to_time(value)
        when :time      then cast_to_time(value)
        when :date      then cast_to_datetime(value)
        when :boolean   then value == true or (value =~ /^t(rue)?$/i) == 0 or value.to_s == '1'
        else super
        end
      end
      
      def cast_to_time(value)
        return value if value.is_a?(Time)
        time_array = ParseDate.parsedate(value)
        Time.send(Base.default_timezone, *time_array) rescue nil
      end

      def cast_to_datetime(value)
        return value.to_time if value.is_a?(DBI::Timestamp)
        
        if value.is_a?(Time)
          if value.year != 0 and value.month != 0 and value.day != 0
            return value
          else
            return Time.mktime(2000, 1, 1, value.hour, value.min, value.sec) rescue nil
          end
        end
   
        if value.is_a?(DateTime)
          return Time.mktime(value.year, value.mon, value.day, value.hour, value.min, value.sec)
        end
        
        return cast_to_time(value) if value.is_a?(Date) or value.is_a?(String) rescue nil
        value
      end
      
      # TODO: Find less hack way to convert DateTime objects into Times
      
      def self.string_to_time(value)
        if value.is_a?(DateTime)
          return Time.mktime(value.year, value.mon, value.day, value.hour, value.min, value.sec)
        else
          super
        end
      end

      # These methods will only allow the adapter to insert binary data with a length of 7K or less
      # because of a SQL Server statement length policy.
      # Convert strings to hex before storing in the database
      def self.string_to_binary(value)
        "0x#{value.unpack("H*")[0]}"
      end

      def self.binary_to_string(value)
       # TODO: Need to remove conditional pack (should always have to pack hex characters into blob)
        # Assigning a value to a binary column causes the string_to_binary to hexify it
        # This hex value is stored in the DB but the original value is retained in the 
        # cache.  By forcing reload, the value coming into binary_to_string will always
        # be hex.  Need to force reload or update the cached column's value to match what is sent to the DB.
        value =~ /[^[:xdigit:]]/ ? value : [value].pack('H*')
      end
    end

    # In ADO mode, this adapter will ONLY work on Windows systems, 
    # since it relies on Win32OLE, which, to my knowledge, is only 
    # available on Windows.
    #
    # This mode also relies on the ADO support in the DBI module. If you are using the
    # one-click installer of Ruby, then you already have DBI installed, but
    # the ADO module is *NOT* installed. You will need to get the latest
    # source distribution of Ruby-DBI from http://ruby-dbi.sourceforge.net/
    # unzip it, and copy the file 
    # <tt>src/lib/dbd_ado/ADO.rb</tt> 
    # to
    # <tt>X:/Ruby/lib/ruby/site_ruby/1.8/DBD/ADO/ADO.rb</tt> 
    # (you will more than likely need to create the ADO directory).
    # Once you've installed that file, you are ready to go.
    #
    # In ODBC mode, the adapter requires the ODBC support in the DBI module which requires
    # the Ruby ODBC module.  Ruby ODBC 0.996 was used in development and testing,
    # and it is available at http://www.ch-werner.de/rubyodbc/
    #
    # Options:
    #
    # * <tt>:mode</tt>      -- ADO or ODBC. Defaults to ADO.
    # * <tt>:username</tt>  -- Defaults to sa.
    # * <tt>:password</tt>  -- Defaults to empty string.
    #
    # ADO specific options:
    #
    # * <tt>:host</tt>      -- Defaults to localhost.
    # * <tt>:database</tt>  -- The name of the database. No default, must be provided.
    #
    # ODBC specific options:                   
    #
    # * <tt>:dsn</tt>       -- Defaults to nothing.
    #
    # ADO code tested on Windows 2000 and higher systems,
    # running ruby 1.8.2 (2004-07-29) [i386-mswin32], and SQL Server 2000 SP3.
    #
    # ODBC code tested on a Fedora Core 4 system, running FreeTDS 0.63, 
    # unixODBC 2.2.11, Ruby ODBC 0.996, Ruby DBI 0.0.23 and Ruby 1.8.2.
    # [Linux strongmad 2.6.11-1.1369_FC4 #1 Thu Jun 2 22:55:56 EDT 2005 i686 i686 i386 GNU/Linux]
    class SQLServerAdapter < AbstractAdapter
    
      # add synchronization to adapter to prevent 'invalid cursor state' error
      require 'sync'
      def initialize(connection, logger, connection_options=nil)
        super(connection, logger)
        @connection_options = connection_options
        @sql_connection_lock = Sync.new
      end

      # change defaults for text and binary to use varchar(max) and varbinary(max) types
      def native_database_types
        {
          :primary_key => "int NOT NULL IDENTITY(1, 1) PRIMARY KEY",
          :string      => { :name => "varchar", :limit => 255  },
          :text        => { :name => "varchar(max)" },
          :integer     => { :name => "int" },
          :float       => { :name => "float", :limit => 8 },
          :decimal     => { :name => "decimal" },
          :datetime    => { :name => "datetime" },
          :timestamp   => { :name => "datetime" },
          :time        => { :name => "datetime" },
          :date        => { :name => "datetime" },
          :binary      => { :name => "varbinary(max)"},
          :boolean     => { :name => "bit"}
        }
      end

      def adapter_name
        'SQLServer'
      end
      
      def supports_migrations? #:nodoc:
        true
      end

      # Set limit to nil if text or binary due to issues passing the limit on these types in SQL Server 
      # SQL server complains about the data exceeding 8000 bytes
      def type_to_sql(type, limit = nil, precision = nil, scale = nil) #:nodoc:
        limit = nil if %w{text binary}.include?(type.to_s)
        return super unless type.to_s == 'integer'

        if limit.nil? || limit == 4
          'integer'
        elsif limit < 4
          'smallint'
        else
          'bigint'
        end
      end

      # CONNECTION MANAGEMENT ====================================#

      # Returns true if the connection is active.
      def active?
        @connection.execute("SELECT 1").finish
        true
      rescue DBI::DatabaseError, DBI::InterfaceError
        false
      end

      # Reconnects to the database, returns false if no connection could be made.
      def reconnect!
        disconnect!
        @connection = DBI.connect(*@connection_options)
      rescue DBI::DatabaseError => e
        @logger.warn "#{adapter_name} reconnection failed: #{e.message}" if @logger
        false
      end
      
      # Disconnects from the database
      
      def disconnect!
        @sql_connection_lock.synchronize(:EX) do        
          begin
            @connection.disconnect 
          rescue nil
          end
        end
      end

      # Add synchronization for the db connection to ensure no one else is using this one 
      # prevents 'invalid cursor state' error
      def select_rows(sql, name = nil)
        rows = []
        repair_special_columns(sql)
        log(sql, name) do
          @sql_connection_lock.synchronize(:EX) do 
            @connection.select_all(sql) do |row|
              record = []
              row.each do |col|
                if col.is_a? DBI::Timestamp
                  record << col.to_time
                else
                  record << col
                end
              end
              rows << record
            end
          end
        end
        rows
      end
      
      # Add synchronization for the db connection to ensure no one else is using this one 
      # prevents 'invalid cursor state' error
      def columns(table_name, name = nil)
        return [] if table_name.blank?
        table_name = table_name.to_s if table_name.is_a?(Symbol)
        table_name = table_name.split('.')[-1] unless table_name.nil?
        table_name = table_name.gsub(/[\[\]]/, '')
        # Added code to handle varchar(max), varbinary(max), nvarchar(max) returning a length of -1
        # this manifested itself in session data since Rails believed the column was too small
        sql = %Q{
          SELECT 
            cols.COLUMN_NAME as ColName,  
            cols.COLUMN_DEFAULT as DefaultValue,
            cols.NUMERIC_SCALE as numeric_scale,
            cols.NUMERIC_PRECISION as numeric_precision, 
            cols.DATA_TYPE as ColType, 
            cols.IS_NULLABLE As IsNullable,  
            CASE
              WHEN cols.DATA_TYPE IN ('varchar', 'nvarchar', 'varbinary') AND COL_LENGTH(cols.TABLE_NAME, cols.COLUMN_NAME) = -1 THEN 2147483648
              ELSE COL_LENGTH(cols.TABLE_NAME, cols.COLUMN_NAME)
            END as Length,  
            COLUMNPROPERTY(OBJECT_ID(cols.TABLE_NAME), cols.COLUMN_NAME, 'IsIdentity') as IsIdentity,  
            cols.NUMERIC_SCALE as Scale 
          FROM INFORMATION_SCHEMA.COLUMNS cols 
          WHERE cols.TABLE_NAME = '#{table_name}'   
        }
        # Comment out if you want to have the Columns select statment logged.
        # Personally, I think it adds unnecessary bloat to the log. 
        # If you do comment it out, make sure to un-comment the "result" line that follows
          result = log(sql, name) do 
            @sql_connection_lock.synchronize(:EX) do
              @connection.select_all(sql)
            end
          end
          columns = []
          result.each do |field|
            default = field[:DefaultValue].to_s.gsub!(/[()\']/,"") =~ /null/i ? nil : field[:DefaultValue]
            if field[:ColType] =~ /numeric|decimal/i
              type = "#{field[:ColType]}(#{field[:numeric_precision]},#{field[:numeric_scale]})"
            else
              type = "#{field[:ColType]}(#{field[:Length]})"
          end
          is_identity = field[:IsIdentity] == 1
          is_nullable = field[:IsNullable] == 'YES'
          columns << SQLServerColumn.new(field[:ColName], default, type, is_identity, is_nullable)
        end
        columns
      end

      def insert(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        execute(sql, name)
        id_value || select_one("SELECT @@IDENTITY AS Ident")["Ident"]
      end

      def update(sql, name = nil)
        execute(sql, name) do |handle|
          handle.rows
        end || select_one("SELECT @@ROWCOUNT AS AffectedRows")["AffectedRows"]        
      end
      
      alias_method :delete, :update

      # override execute to synchronize the connection
      def execute(sql, name = nil)
        if sql =~ /^\s*INSERT/i && (table_name = query_requires_identity_insert?(sql))
          log(sql, name) do
            with_identity_insert_enabled(table_name) do 
              @sql_connection_lock.synchronize(:EX) do     
                @connection.execute(sql) do |handle|
                  yield(handle) if block_given?
                end
              end
            end
          end
        else
          log(sql, name) do
            @sql_connection_lock.synchronize(:EX) do     
              @connection.execute(sql) do |handle|
                yield(handle) if block_given?
              end
            end
          end
        end
      end


      # Add synchronization for the db connection to ensure no one else is using this one 
      # prevents 'Could not change transaction status' error      
      def begin_db_transaction
        @sql_connection_lock.synchronize(:EX) do
          begin        
            @connection["AutoCommit"] = false
          rescue Exception => e
            @connection["AutoCommit"] = true
          end
        end
      end
      def commit_db_transaction
        @sql_connection_lock.synchronize(:EX) do        
          begin      
            @connection.commit
          ensure
            @connection["AutoCommit"] = true
          end
        end
      end

      def rollback_db_transaction
        @sql_connection_lock.synchronize(:EX) do        
          begin
            @connection.rollback
          ensure
            @connection["AutoCommit"] = true
          end
        end
      end

      def quote(value, column = nil)
        return value.quoted_id if value.respond_to?(:quoted_id)

        case value
          when TrueClass             then '1'
          when FalseClass            then '0'
          when Time, DateTime        then "'#{value.strftime("%Y%m%d %H:%M:%S")}'"
          when Date                  then "'#{value.strftime("%Y%m%d")}'"
          else                       super
        end
      end

      def quote_string(string)
        string.gsub(/\'/, "''")
      end

      def quote_column_name(name)
        "[#{name}]"
      end

      def add_limit_offset!(sql, options)
        if options[:limit] and options[:offset]
          total_rows = @connection.select_all("SELECT count(*) as TotalRows from (#{sql.gsub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT#{$1} TOP 1000000000")}) tally")[0][:TotalRows].to_i
          if (options[:limit] + options[:offset]) >= total_rows
            options[:limit] = (total_rows - options[:offset] >= 0) ? (total_rows - options[:offset]) : 0
          end
          sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i, "SELECT * FROM (SELECT TOP #{options[:limit]} * FROM (SELECT#{$1} TOP #{options[:limit] + options[:offset]} ")
          sql << ") AS tmp1"
          if options[:order]
            options[:order] = options[:order].split(',').map do |field|
              parts = field.split(" ")
              tc = parts[0]
              if sql =~ /\.\[/ and tc =~ /\./ # if column quoting used in query
                tc.gsub!(/\./, '\\.\\[')
                tc << '\\]'
              end
              if sql =~ /#{tc} AS (t\d_r\d\d?)/
                parts[0] = $1
              elsif parts[0] =~ /\w+\.(\w+)/
                parts[0] = $1
              end
              parts.join(' ')
            end.join(', ')
            sql << " ORDER BY #{change_order_direction(options[:order])}) AS tmp2 ORDER BY #{options[:order]}"
          else
            sql << " ) AS tmp2"
          end
        elsif sql !~ /^\s*SELECT (@@|COUNT\()/i
          sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i) do
            "SELECT#{$1} TOP #{options[:limit]}"
          end unless options[:limit].nil?
        end
      end

      def recreate_database(name)
        drop_database(name)
        create_database(name)
      end

      def drop_database(name)
        execute "DROP DATABASE #{name}"
      end

      def create_database(name)
        execute "CREATE DATABASE #{name}"
      end
   
      def current_database
        @connection.select_one("select DB_NAME()")[0]
      end

      def tables(name = nil)
        execute("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'", name) do |sth|
          sth.inject([]) do |tables, field|
            table_name = field[0]
            tables << table_name unless table_name == 'dtproperties'
            tables
          end
        end
      end

      def indexes(table_name, name = nil)
        ActiveRecord::Base.connection.instance_variable_get("@connection")["AutoCommit"] = false
        indexes = []        
        execute("EXEC sp_helpindex '#{table_name}'", name) do |sth|
          sth.each do |index| 
            unique = index[1] =~ /unique/
            primary = index[1] =~ /primary key/
            if !primary
              indexes << IndexDefinition.new(table_name, index[0], unique, index[2].split(", "))
            end
          end
        end
        indexes
        ensure
          ActiveRecord::Base.connection.instance_variable_get("@connection")["AutoCommit"] = true
      end
            
      def rename_table(name, new_name)
        execute "EXEC sp_rename '#{name}', '#{new_name}'"
      end
      
      # Adds a new column to the named table.
      # See TableDefinition#column for details of the options you can use.
      def add_column(table_name, column_name, type, options = {})
        add_column_sql = "ALTER TABLE #{table_name} ADD #{quote_column_name(column_name)} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
        add_column_options!(add_column_sql, options)
        # TODO: Add support to mimic date columns, using constraints to mark them as such in the database
        # add_column_sql << " CONSTRAINT ck__#{table_name}__#{column_name}__date_only CHECK ( CONVERT(CHAR(12), #{quote_column_name(column_name)}, 14)='00:00:00:000' )" if type == :date       
        execute(add_column_sql)
      end
       
      def rename_column(table, column, new_column_name)
        execute "EXEC sp_rename '#{table}.#{column}', '#{new_column_name}'"
      end
      
      # database_statements line 108 Set the SQL specific rowlocking
      # was previously generating invalid syntax for SQL server
      def add_lock!(sql, options)
        case lock = options[:lock]
        when true then sql << "WITH(HOLDLOCK, ROWLOCK) "
        when String then sql << "#{lock} "
        end
      end
      

      
      # Delete the default options if it's nil. Adapter was adding default NULL contraints 
      # to all columns which caused problems when trying to alter the column
      def add_column_options!(sql, options) #:nodoc:
        options.delete(:default) if options[:default].nil? 
        super
      end

      # calculate column size to fix issue
      # size XXXXX given to the column 'data' exceeds the maximum allowed for any data type (8000)
      def column_total_size(table_name)
        return nil if table_name.blank?
        table_name = table_name.to_s if table_name.is_a?(Symbol)
        table_name = table_name.split('.')[-1] unless table_name.nil?
        table_name = table_name.gsub(/[\[\]]/, '')
        sql = %Q{
                SELECT SUM(COL_LENGTH(cols.TABLE_NAME, cols.COLUMN_NAME)) as Length
                FROM INFORMATION_SCHEMA.COLUMNS cols 
                WHERE cols.TABLE_NAME = '#{table_name}'   
        }
        # Comment out if you want to have the Columns select statment logged.
        # Personally, I think it adds unnecessary bloat to the log. If you do
        # comment it out, make sure to un-comment the "result" line that follows
        result = log(sql, name) do 
          @sql_connection_lock.synchronize(:EX) { @connection.select_all(sql) }
        end
        field[:Length].to_i
      end
      # if binary, calculate te the remaining amount for size
      # issue: size XXXXX given to the column 'data' exceeds the maximum allowed for any data type (8000)
      def change_column(table_name, column_name, type, options = {}) #:nodoc:
        # $log.debug "change_column"
        sql_commands = []
        
        # Handle conversion of text columns to binary columns by first
        # converting to varchar. We determine the amount of space left for the
        # columns so we can get the most out of the conversion.
        if type == :binary
          col = self.columns(table_name, column_name)
          sql_commands << "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} #{type_to_sql(:string, 8000 - column_total_size(table_name))}" if col && col.type == :text
        end
        
        sql_commands << "ALTER TABLE #{table_name} ALTER COLUMN #{column_name} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
        if options_include_default?(options)
          remove_default_constraint(table_name, column_name)
          sql_commands << "ALTER TABLE #{table_name} ADD CONSTRAINT DF_#{table_name}_#{column_name} DEFAULT #{quote(options[:default], options[:column])} FOR #{column_name}"
        end
        sql_commands.each {|c|
          execute(c)
        }
      end
      
      def remove_column(table_name, column_name)
        remove_check_constraints(table_name, column_name)
        remove_default_constraint(table_name, column_name)
        execute "ALTER TABLE [#{table_name}] DROP COLUMN [#{column_name}]"
      end
      
      def remove_default_constraint(table_name, column_name)
        constraints = select "select def.name from sysobjects def, syscolumns col, sysobjects tab where col.cdefault = def.id and col.name = '#{column_name}' and tab.name = '#{table_name}' and col.id = tab.id"
        
        constraints.each do |constraint|
          execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{constraint["name"]}"
        end
      end
      
      def remove_check_constraints(table_name, column_name)
        # TODO remove all constraints in single method
        constraints = select "SELECT CONSTRAINT_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_NAME = '#{table_name}' and COLUMN_NAME = '#{column_name}'"
        constraints.each do |constraint|
          execute "ALTER TABLE #{table_name} DROP CONSTRAINT #{constraint["CONSTRAINT_NAME"]}"
        end
      end
      
      def remove_index(table_name, options = {})
        execute "DROP INDEX #{table_name}.#{quote_column_name(index_name(table_name, options))}"
      end

      private 
        def select(sql, name = nil)
          repair_special_columns(sql)

          result = []          
          execute(sql) do |handle|
            handle.each do |row|
              row_hash = {}
              row.each_with_index do |value, i|
                if value.is_a? DBI::Timestamp
                  value = DateTime.new(value.year, value.month, value.day, value.hour, value.minute, value.sec)
                end
                row_hash[handle.column_names[i]] = value
              end
              result << row_hash
            end
          end
          result
        end

        # Turns IDENTITY_INSERT ON for table during execution of the block
        # N.B. This sets the state of IDENTITY_INSERT to OFF after the
        # block has been executed without regard to its previous state

        def with_identity_insert_enabled(table_name, &block)
          set_identity_insert(table_name, true)
          yield
        ensure
          set_identity_insert(table_name, false)  
        end
        
        def set_identity_insert(table_name, enable = true)
          execute "SET IDENTITY_INSERT #{table_name} #{enable ? 'ON' : 'OFF'}"
        rescue Exception => e
          raise ActiveRecordError, "IDENTITY_INSERT could not be turned #{enable ? 'ON' : 'OFF'} for table #{table_name}"  
        end

        def get_table_name(sql)
          if sql =~ /^\s*insert\s+into\s+([^\(\s]+)\s*|^\s*update\s+([^\(\s]+)\s*/i
            $1
          elsif sql =~ /from\s+([^\(\s]+)\s*/i
            $1
          else
            nil
          end
        end

        def identity_column(table_name)
          @table_columns = {} unless @table_columns
          @table_columns[table_name] = columns(table_name) if @table_columns[table_name] == nil
          @table_columns[table_name].each do |col|
            return col.name if col.identity
          end

          return nil
        end

        def query_requires_identity_insert?(sql)
          table_name = get_table_name(sql)
          id_column = identity_column(table_name)
          sql =~ /\[#{id_column}\]/ ? table_name : nil
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

        def get_special_columns(table_name)
          special = []
          @table_columns ||= {}
          @table_columns[table_name] ||= columns(table_name)
          @table_columns[table_name].each do |col|
            special << col.name if col.is_special
          end
          special
        end

        def repair_special_columns(sql)
          special_cols = get_special_columns(get_table_name(sql))
          for col in special_cols.to_a
            sql.gsub!(Regexp.new(" #{col.to_s} = "), " #{col.to_s} LIKE ")
            sql.gsub!(/ORDER BY #{col.to_s}/i, '')
          end
          sql
        end

    end #class SQLServerAdapter < AbstractAdapter
    # If value is a string and destination column is binary, don't quote the string for MS SQL
    module Quoting
      # Quotes the column value to help prevent
      # {SQL injection attacks}[http://en.wikipedia.org/wiki/SQL_injection].
      def quote(value, column = nil)
        # records are quoted as their primary key
        return value.quoted_id if value.respond_to?(:quoted_id)
        #        puts "Type: #{column.type}  Name: #{column.name}" if column
        case value
        when String, ActiveSupport::Multibyte::Chars
          value = value.to_s
          if column && column.type == :binary && column.class.respond_to?(:string_to_binary) 
            column.class.string_to_binary(value) 
          elsif column && [:integer, :float].include?(column.type)
            value = column.type == :integer ? value.to_i : value.to_f
            value.to_s
          else
            "'#{quote_string(value)}'" # ' (for ruby-mode)
          end
        when NilClass                 then "NULL"
        when TrueClass                then (column && column.type == :integer ? '1' : quoted_true)
        when FalseClass               then (column && column.type == :integer ? '0' : quoted_false)
        when Float, Fixnum, Bignum    then value.to_s
          # BigDecimals need to be output in a non-normalized form and quoted.
        when BigDecimal               then value.to_s('F')
        when Date                     then "'#{value.to_s}'"
        when Time, DateTime           then "'#{quoted_date(value)}'"
        else                          "'#{quote_string(value.to_yaml)}'"
        end
      end    
    end
  end #module ConnectionAdapters
end #module ActiveRecord
