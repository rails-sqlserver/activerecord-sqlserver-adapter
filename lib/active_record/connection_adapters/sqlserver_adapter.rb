require 'active_record/connection_adapters/abstract_adapter'
require 'base64'

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
        driver_url = "DBI:ADO:Provider=SQLOLEDB;Data Source=#{host};Initial Catalog=#{database};User ID=#{username};Password=#{password};"
      end
      conn      = DBI.connect(driver_url, username, password)
      conn["AutoCommit"] = autocommit
      ConnectionAdapters::SQLServerAdapter.new(conn, logger, [driver_url, username, password])
    end
    
    private
    
    # Add basic support for SQL server locking hints
    # In the case of SQL server, the lock value must follow the FROM clause
    # Mysql:     SELECT * FROM tst where testID = 10 LOCK IN share mode
    # SQLServer: SELECT * from tst WITH (HOLDLOCK, ROWLOCK) where testID = 10
    # h-lame: OK, so these 2 methods should be a patch to rails ideally, so we don't
    #         have to play catch up against rails itself should construct_finder_sql ever
    #         change
    def self.construct_finder_sql(options)
      scope = scope(:find)
      sql  = "SELECT #{options[:select] || (scope && scope[:select]) || ((options[:joins] || (scope && scope[:joins])) && quoted_table_name + '.*') || '*'} "
      sql << "FROM #{(scope && scope[:from]) || options[:from] || quoted_table_name} "
      
      add_lock!(sql, options, scope) if ActiveRecord::Base.connection.adapter_name == "SQLServer" && !options[:lock].blank? # SQLServer

      # merge_joins isn't defined in 2.1.1, but appears in edge
      if defined?(merge_joins)
      # The next line may fail with a nil error under 2.1.1 or other non-edge rails versions - Use this instead: add_joins!(sql, options, scope)
       add_joins!(sql, options[:joins], scope)
      else
       add_joins!(sql, options, scope)
      end

      add_conditions!(sql, options[:conditions], scope)

      add_group!(sql, options[:group], scope)
      add_order!(sql, options[:order], scope)
      add_limit!(sql, options, scope)
      add_lock!(sql, options, scope) unless ActiveRecord::Base.connection.adapter_name == "SQLServer" #  Not SQLServer
      sql
    end
    
    # Overwrite the ActiveRecord::Base method for SQL server.
    # GROUP BY is necessary for distinct orderings
    def self.construct_finder_sql_for_association_limiting(options, join_dependency)
      scope       = scope(:find)
      is_distinct = !options[:joins].blank? || include_eager_conditions?(options) || include_eager_order?(options)

      sql = "SELECT #{table_name}.#{connection.quote_column_name(primary_key)} FROM #{table_name} "

      if is_distinct
        sql << join_dependency.join_associations.collect(&:association_join).join
        # merge_joins isn't defined in 2.1.1, but appears in edge
        if defined?(merge_joins)
        # The next line may fail with a nil error under 2.1.1 or other non-edge rails versions - Use this instead: add_joins!(sql, options, scope)
         add_joins!(sql, options[:joins], scope)
        else
         add_joins!(sql, options, scope)
        end
      end

      add_conditions!(sql, options[:conditions], scope)
      add_group!(sql, options[:group], scope)

      if options[:order] && is_distinct
        if sql =~ /GROUP\s+BY/i
          sql << ", #{table_name}.#{connection.quote_column_name(primary_key)}"
        else
          sql << " GROUP BY #{table_name}.#{connection.quote_column_name(primary_key)}"
        end #if sql =~ /GROUP BY/i

        connection.add_order_by_for_association_limiting!(sql, options)
      else
        add_order!(sql, options[:order], scope)
      end

      add_limit!(sql, options, scope)

      return sanitize_sql(sql)
    end
   
  end
  
  module ConnectionAdapters
    
    class SQLServerColumn < Column #:nodoc:
      
      attr_reader :identity, :is_special, :is_utf8
      
      def initialize(info)
        if info[:type] =~ /numeric|decimal/i
          type = "#{info[:type]}(#{info[:numeric_precision]},#{info[:numeric_scale]})"
        else
          type = "#{info[:type]}(#{info[:length]})"
        end
        super(info[:name], info[:default_value], type, info[:is_nullable] == 1)
        @identity = info[:is_identity]
        # TODO: Not sure if these should also be special: varbinary(max), nchar, nvarchar(max) 
        @is_special = ["text", "ntext", "image"].include?(info[:type])
        # Added nchar and nvarchar(max) for unicode types
        #  http://www.teratrax.com/sql_guide/data_types/sql_server_data_types.html
        @is_utf8 = type =~ /nvarchar|ntext|nchar|nvarchar(max)/i
        # TODO: check ok to remove @scale = scale_value
        @limit = nil unless limitable?(type)
      end
      
      def identity?
        @identity
      end
      
      def limitable?(type)
        # SQL Server only supports limits on *char and float types
        # although for schema dumping purposes it's useful to know that (big|small)int are 2|8 respectively.
        @type == :float || @type == :string || (@type == :integer && type =~ /^(big|small)int/)
      end

      def simplified_type(field_type)
        case field_type
          when /real/i              then :float
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
        when :datetime  then self.class.cast_to_datetime(value)
        when :timestamp then self.class.cast_to_time(value)
        when :time      then self.class.cast_to_time(value)
        when :date      then self.class.cast_to_datetime(value)
        else super
        end
      end

      def type_cast_code(var_name)
        case type
        when :datetime  then "#{self.class.name}.cast_to_datetime(#{var_name})"
        when :timestamp then "#{self.class.name}.cast_to_time(#{var_name})"
        when :time      then "#{self.class.name}.cast_to_time(#{var_name})"
        when :date      then "#{self.class.name}.cast_to_datetime(#{var_name})"
        else super
        end
      end
      
      
      class << self
        
        def cast_to_datetime(value)
          return value.to_time if value.is_a?(DBI::Timestamp)
          return string_to_time(value) if value.is_a?(Time)
          return string_to_time(value) if value.is_a?(DateTime)
          return cast_to_time(value) if value.is_a?(String)
          value
        end

        def cast_to_time(value)
          return value if value.is_a?(Time)
          time_hash = Date._parse(value)
          time_hash[:sec_fraction] = 0 # REVISIT: microseconds(time_hash)
          new_time(*time_hash.values_at(:year, :mon, :mday, :hour, :min, :sec, :sec_fraction)) rescue nil
        end

        def string_to_time(value)
          if value.is_a?(DateTime) || value.is_a?(Time)
            # The DateTime comes in as '2008-08-08T17:57:28+00:00'
            # Original code was taking a UTC DateTime, ignored the time zone by
            # creating a localized Time object,  ex: 'FRI Aug 08 17:57:28 +04 2008'
            # Instead, let Time.parse translate the DateTime string including it's timezone
            # If Rails is UTC, call .utc, otherwise return a local time value
            return Base.default_timezone == :utc ? Time.parse(value.to_s).utc : Time.parse(value.to_s)
          else
            super
          end
        end
        
        def string_to_binary(value)
         "0x#{value.unpack("H*")[0]}"
        end
        
        def binary_to_string(value)
          value =~ /[^[:xdigit:]]/ ? value : [value].pack('H*')
        end
        
        protected
        
        def new_time(year, mon, mday, hour, min, sec, microsec = 0)
          # Treat 0000-00-00 00:00:00 as nil.
          return nil if year.nil? || year == 0
          Time.time_with_datetime_fallback(Base.default_timezone, year, mon, mday, hour, min, sec, microsec) rescue nil
        end
        
      end #class << self
      
    end #SQLServerColumn
    
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
    # * <tt>:windows_auth</tt> -- Defaults to "User ID=#{username};Password=#{password}"
    #
    # ADO specific options:
    #
    # * <tt>:host</tt>      -- Defaults to localhost.
    # * <tt>:database</tt>  -- The name of the database. No default, must be provided.
    # * <tt>:windows_auth</tt> -- Use windows authentication instead of username/password.
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
      
      ADAPTER_NAME            = 'SQLServer'.freeze
      DATABASE_VERSION_REGEXP = /Microsoft SQL Server\s+(\d{4})/
      SUPPORTED_VERSIONS      = [2000,2005].freeze
      
      def initialize(connection, logger, connection_options=nil)
        super(connection, logger)
        @connection_options = connection_options
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
      
      def supports_ddl_transactions?
        true
      end
      
      def native_database_types
        txt = sqlserver_2005? ? "varchar(max)"   : "text"
        bin = sqlserver_2005? ? "varbinary(max)" : "image"
        {
          :primary_key => "int NOT NULL IDENTITY(1, 1) PRIMARY KEY",
          :string      => { :name => "varchar", :limit => 255  },
          :text        => { :name =>  txt },
          :integer     => { :name => "int" },
          :float       => { :name => "float", :limit => 8 },
          :decimal     => { :name => "decimal" },
          :datetime    => { :name => "datetime" },
          :timestamp   => { :name => "datetime" },
          :time        => { :name => "datetime" },
          :date        => { :name => "datetime" },
          :binary      => { :name =>  bin },
          :boolean     => { :name => "bit"}
        }
      end
      
      def database_version
        select_value "SELECT @@version"
      end
      
      def database_year
        DATABASE_VERSION_REGEXP.match(database_version)[1].to_i
      end
      
      def sqlserver_2000?
        database_year == 2000
      end
      
      def sqlserver_2005?
        database_year == 2005
      end
      
      # QUOTING ==================================================#
      
      def quote(value, column = nil)
        if value.kind_of?(String) && column && column.type == :binary
          column.class.string_to_binary(value)
        else
          super
        end
      end
      
      def quote_string(string)
        string.gsub(/\'/, "''")
      end
      
      # Quotes the given column identifier.
      # 
      #   quote_column_name('foo') # => '[foo]'
      #   quote_column_name(:foo) # => '[foo]'
      #   quote_column_name('foo.bar') # => '[foo].[bar]'
      def quote_column_name(identifier)
        identifier.to_s.split('.').collect do |name|
          "[#{name}]"          
        end.join(".")
      end
      
      def quote_table_name(name)
        name_split_on_dots = name.to_s.split('.')
        if name_split_on_dots.length == 3
          # name is on the form "foo.bar.baz"
          "[#{name_split_on_dots[0]}].[#{name_split_on_dots[1]}].[#{name_split_on_dots[2]}]"
        else
          super(name)
        end
      end
      
      def quoted_true
        '1'
      end

      def quoted_false
        '0'
      end
      
      # TODO: I get the feeling this needs to go and that it is patching something else wrong.
      def quoted_date(value)
        if value.acts_like?(:time)
          value.strftime("%Y%m%d %H:%M:%S")
        elsif value.acts_like?(:date)
          value.strftime("%Y%m%d")
        else
          super
        end
      end
      
      
      # REFERENTIAL INTEGRITY ====================================#
      # TODO: Add #disable_referential_integrity if we can use it
      
      
      # DATABASE STATEMENTS ======================================
      
      def select_rows(sql, name = nil)
        rows = []
        repair_special_columns(sql)
        log(sql, name) do
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
        rows
      end
      
      def execute(sql, name = nil)
        if sql =~ /^\s*INSERT/i && (table_name = query_requires_identity_insert?(sql))
          log(sql, name) do
            with_identity_insert_enabled(table_name) do
              @connection.execute(sql) do |handle|
                yield(handle) if block_given?
              end
            end
          end
        else
          log(sql, name) do
            @connection.execute(sql) do |handle|
              yield(handle) if block_given?
            end
          end
        end
      end
      
      def begin_db_transaction
        @connection["AutoCommit"] = false
      rescue Exception => e
        @connection["AutoCommit"] = true
      end
      
      def commit_db_transaction
        @connection.commit
      ensure
        @connection["AutoCommit"] = true
      end
      
      def rollback_db_transaction
        @connection.rollback
      ensure
        @connection["AutoCommit"] = true
      end
      
      def add_limit_offset!(sql, options)
        if options[:offset]
          raise ArgumentError, "offset should have a limit" unless options[:limit]
          unless options[:offset].kind_of?Integer
            if options[:offset] =~ /^\d+$/
              options[:offset] = options[:offset].to_i
            else
              raise ArgumentError, "offset should be an integer"
            end
          end
        end

        if options[:limit] && !(options[:limit].kind_of?Integer)
          # is it just a string which should be an integer?
          if options[:limit] =~ /^\d+$/
            options[:limit] = options[:limit].to_i
          else
            raise ArgumentError, "limit should be an integer"
          end
        end

        if options[:limit] and options[:offset]
          total_rows = @connection.select_all("SELECT count(*) as TotalRows from (#{sql.gsub(/\bSELECT(\s+DISTINCT)?\b/i, "SELECT#{$1} TOP 1000000000")}) tally")[0][:TotalRows].to_i
          if (options[:limit] + options[:offset]) >= total_rows
            options[:limit] = (total_rows - options[:offset] >= 0) ? (total_rows - options[:offset]) : 0
          end

          # Wrap the SQL query in a bunch of outer SQL queries that emulate proper LIMIT,OFFSET support.
          sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i, "SELECT * FROM (SELECT TOP #{options[:limit]} * FROM (SELECT#{$1} TOP #{options[:limit] + options[:offset]}")
          sql << ") AS tmp1"

          if options[:order]
            order = options[:order].split(',').map do |field|
              order_by_column, order_direction = field.split(" ")
              order_by_column = quote_column_name(order_by_column)

              # Investigate the SQL query to figure out if the order_by_column has been renamed.
              if sql =~ /#{Regexp.escape(order_by_column)} AS (t\d_r\d\d?)/
                # Fx "[foo].[bar] AS t4_r2" was found in the SQL. Use the column alias (ie 't4_r2') for the subsequent orderings
                order_by_column = $1
              elsif order_by_column =~ /\w+\.\[?(\w+)\]?/
                order_by_column = $1
              else
                # It doesn't appear that the column name has been renamed as part of the query. Use just the column
                # name rather than the full identifier for the outer queries.
                order_by_column = order_by_column.split('.').last
              end

              # Put the column name and eventual direction back together
              [order_by_column, order_direction].join(' ').strip
            end.join(', ')

            sql << " ORDER BY #{change_order_direction(order)}) AS tmp2 ORDER BY #{order}"
          else
            sql << ") AS tmp2"
          end
        elsif sql !~ /^\s*SELECT (@@|COUNT\()/i
          sql.sub!(/^\s*SELECT(\s+DISTINCT)?/i) do
            "SELECT#{$1} TOP #{options[:limit]}"
          end unless options[:limit].nil? || options[:limit] < 1
        end
      end
      
      # Appends a locking clause to an SQL statement.
      # This method *modifies* the +sql+ parameter.
      #   # SELECT * FROM suppliers FOR UPDATE
      #   add_lock! 'SELECT * FROM suppliers', :lock => true
      #   add_lock! 'SELECT * FROM suppliers', :lock => ' WITH(HOLDLOCK, ROWLOCK)'
      # http://blog.sqlauthority.com/2007/04/27/sql-server-2005-locking-hints-and-examples/
      def add_lock!(sql, options)
        case lock = options[:lock]
        when true then sql << "WITH(HOLDLOCK, ROWLOCK) "
        when String then sql << "#{lock} "
        end
      end
      
      def empty_insert_statement(table_name)
        "INSERT INTO #{table_name} DEFAULT VALUES"
      end
      
      def select(sql, name = nil, ignore_special_columns = false)
        repair_special_columns(sql) unless ignore_special_columns
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
      
      def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        set_utf8_values!(sql)
        super || select_value("SELECT SCOPE_IDENTITY() AS Ident")
      end
      
      def update_sql(sql, name = nil)
        set_utf8_values!(sql)
        auto_commiting = @connection["AutoCommit"]
        begin
          begin_db_transaction if auto_commiting
          execute(sql, name)
          affected_rows = select_value("SELECT @@ROWCOUNT AS AffectedRows")
          commit_db_transaction if auto_commiting
          affected_rows
        rescue
          rollback_db_transaction if auto_commiting
          raise
        end
      end
      
      
      # SCHEMA STATEMENTS ========================================#
      
      def tables(name = nil)
        execute("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'", name) do |sth|
          result = sth.inject([]) do |tables, field|
            table_name = field[0]
            tables << table_name unless table_name == 'dtproperties'
            tables
          end
        end
      end
      
      def table_exists?(table_name)
        #If the table is external, see if it has columns
        super(table_name) || (columns(table_name).size>0)
      end
      
      def columns(table_name, name = nil)
        return [] if table_name.blank?
        table_names = table_name.to_s.split('.')
        table_name = table_names[-1]
        table_name = table_name.gsub(/[\[\]]/, '')
        db_name = "#{table_names[0]}." if table_names.length==3

        # COL_LENGTH returns values that do not reflect how much data can be stored in certain data types.
        # COL_LENGTH returns -1 for varchar(max), nvarchar(max), and varbinary(max)
        # COL_LENGTH returns 16 for ntext, text, image types
        # My sessions.data column was varchar(max) and resulted in the following error:
        # Your session data is larger than the data column in which it is to be stored. You must increase the size of your data column if you intend to store large data.
        sql = %{
          SELECT
          columns.COLUMN_NAME as name,
          columns.DATA_TYPE as type,
          CASE
            WHEN columns.COLUMN_DEFAULT = '(null)' OR columns.COLUMN_DEFAULT = '(NULL)' THEN NULL
            ELSE columns.COLUMN_DEFAULT
          END default_value,
          columns.NUMERIC_SCALE as numeric_scale,
          columns.NUMERIC_PRECISION as numeric_precision,
          CASE
            WHEN columns.DATA_TYPE IN ('nvarchar') AND COL_LENGTH(columns.TABLE_NAME, columns.COLUMN_NAME) = -1 THEN 1073741823
            WHEN columns.DATA_TYPE IN ('varchar', 'varbinary') AND COL_LENGTH(columns.TABLE_NAME, columns.COLUMN_NAME) = -1 THEN 2147483647
            WHEN columns.DATA_TYPE IN ('ntext') AND COL_LENGTH(columns.TABLE_NAME, columns.COLUMN_NAME) = 16 THEN 1073741823
            WHEN columns.DATA_TYPE IN ('text', 'image') AND COL_LENGTH(columns.TABLE_NAME, columns.COLUMN_NAME) = 16 THEN 2147483647
            ELSE COL_LENGTH(columns.TABLE_NAME, columns.COLUMN_NAME) 
          END as length,
          CASE
            WHEN columns.IS_NULLABLE = 'YES' THEN 1
            ELSE NULL
          end is_nullable,
          CASE
            WHEN COLUMNPROPERTY(OBJECT_ID(columns.TABLE_NAME), columns.COLUMN_NAME, 'IsIdentity') = 0 THEN NULL
            ELSE 1
          END is_identity
          FROM #{db_name}INFORMATION_SCHEMA.COLUMNS columns
          WHERE columns.TABLE_NAME = '#{table_name}'
          ORDER BY columns.ordinal_position
        }.gsub(/[ \t\r\n]+/,' ')
        result = select(sql, name, true)
        result.collect do |column_info|
          # Remove brackets and outer quotes (if quoted) of default value returned by db, i.e:
          #   "(1)" => "1", "('1')" => "1", "((-1))" => "-1", "('(-1)')" => "(-1)"
          #   Unicode strings will be prefixed with an N. Remove that too.
          column_info.symbolize_keys!
          column_info[:default_value] = column_info[:default_value].match(/\A\(+N?'?(.*?)'?\)+\Z/)[1] if column_info[:default_value]
          SQLServerColumn.new(column_info)
        end
      end
      
      def rename_table(name, new_name)
        execute "EXEC sp_rename '#{name}', '#{new_name}'"
      end
      
      def add_column(table_name, column_name, type, options = {})
        add_column_sql = "ALTER TABLE #{table_name} ADD #{quote_column_name(column_name)} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
        add_column_options!(add_column_sql, options)
        # TODO: Add support to mimic date columns, using constraints to mark them as such in the database
        # add_column_sql << " CONSTRAINT ck__#{table_name}__#{column_name}__date_only CHECK ( CONVERT(CHAR(12), #{quote_column_name(column_name)}, 14)='00:00:00:000' )" if type == :date
        execute(add_column_sql)
      end
      
      def remove_column(table_name, column_name)
        remove_check_constraints(table_name, column_name)
        remove_default_constraint(table_name, column_name)
        remove_indexes(table_name, column_name)
        execute "ALTER TABLE [#{table_name}] DROP COLUMN #{quote_column_name(column_name)}"
      end
      
      def change_column(table_name, column_name, type, options = {}) #:nodoc:
        sql = "ALTER TABLE #{table_name} ALTER COLUMN #{quote_column_name(column_name)} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
        sql << " NOT NULL" if options[:null] == false
        sql_commands = [sql]
        if options_include_default?(options)
          remove_default_constraint(table_name, column_name)
          sql_commands << "ALTER TABLE #{table_name} ADD CONSTRAINT DF_#{table_name}_#{column_name} DEFAULT #{quote(options[:default], options[:column])} FOR #{quote_column_name(column_name)}"
        end
        sql_commands.each {|c|
          execute(c)
        }
      end
      
      def change_column_default(table_name, column_name, default)
        remove_default_constraint(table_name, column_name)
        execute "ALTER TABLE #{table_name} ADD CONSTRAINT DF_#{table_name}_#{column_name} DEFAULT #{quote(default, column_name)} FOR #{quote_column_name(column_name)}"
      end
      
      def rename_column(table_name, column_name, new_column_name)
        if columns(table_name).find{|c| c.name.to_s == column_name.to_s}
          execute "EXEC sp_rename '#{table_name}.#{column_name}', '#{new_column_name}'"
        else
          raise ActiveRecordError, "No such column: #{table_name}.#{column_name}"
        end
      end
      
      def remove_indexes(table_name, column_name)
        __indexes(table_name).select {|idx| idx.columns.include? column_name }.each do |idx|
          remove_index(table_name, {:name => idx.name})
        end
      end

      def remove_index(table_name, options = {})
        execute "DROP INDEX #{table_name}.#{quote_column_name(index_name(table_name, options))}"
      end

      def indexes(table_name, name = nil)
        ActiveRecord::Base.connection.instance_variable_get("@connection")["AutoCommit"] = false
        __indexes(table_name, name)
      ensure
        ActiveRecord::Base.connection.instance_variable_get("@connection")["AutoCommit"] = true
      end
      
      def __indexes(table_name, name = nil)
        indexes = []
        execute("EXEC sp_helpindex '#{table_name}'", name) do |handle|
          if handle.column_info.any?
            handle.each do |index|
              unique = index[1] =~ /unique/
              primary = index[1] =~ /primary key/
              if !primary
                indexes << IndexDefinition.new(table_name, index[0], unique, index[2].split(", ").map {|e| e.gsub('(-)','')})
              end
            end
          end
        end
        indexes
      end

      def add_order_by_for_association_limiting!(sql, options)
        return sql if options[:order].blank?

        # Strip any ASC or DESC from the orders for the select list
        # Build fields and order arrays
        # e.g.: options[:order] = 'table.[id], table2.[col2] desc'
        # fields = ['min(table.[id]) AS id', 'min(table2.[col2]) AS col2']
        # order = ['id', 'col2 desc']
        fields = []
        order = []
        options[:order].split(/\s*,\s*/).each do |str|
          # regex matches 'table_name.[column_name] asc' or 'column_name' ('table_name.', 'asc', '[', and ']' are optional)
          # $1 = 'table_name.[column_name]'
          # $2 = 'column_name'
          # $3 = ' asc'
          str =~ /((?:\w+\.)?\[?(\w+)\]?)(\s+asc|\s+desc)?/i
          fields << "MIN(#{$1}) AS #{$2}"
          order << "#{$2}#{$3}"
        end

        sql.gsub!(/(.+?) FROM/, "\\1, #{fields.join(',')} FROM")
        sql << " ORDER BY #{order.join(',')}"
      end
      
      def type_to_sql(type, limit = nil, precision = nil, scale = nil) #:nodoc:
        # Remove limit for data types which do not require it
        # Valid:   ALTER TABLE sessions ALTER COLUMN [data] varchar(max)
        # Invalid: ALTER TABLE sessions ALTER COLUMN [data] varchar(max)(16777215)
        limit = nil if %w{text varchar(max) nvarchar(max) ntext varbinary(max) image}.include?(native_database_types[type.to_sym][:name])

        return super unless type.to_s == 'integer'

        if limit.nil?
          'integer'
        elsif limit > 4
          'bigint'
        elsif limit < 3
          'smallint'
        else
          'integer'
        end
      end
      
      # Clear the given table and reset the table's id to 1
      # Argument:
      # +table_name+:: (String) Name of the table to be cleared and reset
      def truncate(table_name)
        execute("TRUNCATE TABLE #{table_name}; DBCC CHECKIDENT ('#{table_name}', RESEED, 1)")
      end
      
      def change_column_null(table_name, column_name, null, default = nil)
        column = columns(table_name).find { |c| c.name == column_name.to_s }

        unless null || default.nil?
          execute("UPDATE #{quote_table_name(table_name)} SET #{quote_column_name(column_name)}=#{quote(default)} WHERE #{quote_column_name(column_name)} IS NULL")
        end

        # TODO - work out what the reason is for column.sql_type != type_to_sql(column.type, column.limit, column.precision, column.scale)
        sql = "ALTER TABLE #{table_name} ALTER COLUMN #{quote_column_name(column_name)} #{type_to_sql column.type, column.limit, column.precision, column.scale}"
        sql << " NOT NULL" unless null
        execute sql
      end
      
      # Returns a table's primary key and belonging sequence (not applicable to SQL server).
      def pk_and_sequence_for(table_name)
        @connection["AutoCommit"] = false
        keys = []
        execute("EXEC sp_helpindex '#{table_name}'") do |handle|
          if handle.column_info.any?
            pk_index = handle.detect {|index| index[1] =~ /primary key/ }
            keys << pk_index[2] if pk_index
          end
        end
        keys.length == 1 ? [keys.first, nil] : nil
      ensure
        @connection["AutoCommit"] = true
      end
      
      def remove_default_constraint(table_name, column_name)
        constraints = select "SELECT def.name FROM sysobjects def, syscolumns col, sysobjects tab WHERE col.cdefault = def.id AND col.name = '#{column_name}' AND tab.name = '#{table_name}' AND col.id = tab.id"

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
      
      
      # CONNECTION MANAGEMENT ====================================#
      
      def active?
        @connection.execute("SELECT 1").finish
        true
      rescue DBI::DatabaseError, DBI::InterfaceError
        false
      end

      def reconnect!
        disconnect!
        @connection = DBI.connect(*@connection_options)
      rescue DBI::DatabaseError => e
        @logger.warn "#{adapter_name} reconnection failed: #{e.message}" if @logger
        false
      end

      def disconnect!
        @connection.disconnect rescue nil
      end
      

      # RAKE UTILITY METHODS =====================================#

      def recreate_database(name)
        existing_database = current_database.to_s
        if name.to_s == existing_database
          execute 'USE master' 
        end
        drop_database(name)
        create_database(name)
      ensure
        execute "USE #{existing_database}" if name.to_s == existing_database 
      end

      def drop_database(name)
        retry_count = 0
        max_retries = 1
        begin
          execute "DROP DATABASE #{name}"
        rescue ActiveRecord::StatementInvalid => err
          # Remove existing connections and rollback any transactions if we received the message
          #  'Cannot drop the database 'test' because it is currently in use'
          if err.message =~ /because it is currently in use/
            raise if retry_count >= max_retries
            retry_count += 1
            remove_database_connections_and_rollback(name)
            retry
          else
            raise
          end
        end
      end

      def create_database(name)
        execute "CREATE DATABASE #{name}"
      end
      
      def current_database
        @connection.select_one("SELECT DB_NAME()")[0]
      end

      def remove_database_connections_and_rollback(name)
        # This should disconnect all other users and rollback any transactions for SQL 2000 and 2005
        # http://sqlserver2000.databases.aspfaq.com/how-do-i-drop-a-sql-server-database.html
        execute "ALTER DATABASE #{name} SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
      end
      
      
      
      private
      
      # IDENTITY INSERTS =========================================#
      
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
      
      def query_requires_identity_insert?(sql)
        table_name = get_table_name(sql)
        id_column = identity_column(table_name)
        sql =~ /INSERT[^(]+\([^)]*\[#{id_column}\][^)]*\)/ ? table_name : nil
      end
      
      def identity_column(table_name)
        @table_columns ||= {}
        @table_columns[table_name] = columns(table_name) if @table_columns[table_name] == nil
        @table_columns[table_name].each do |col|
          return col.name if col.identity?
        end
        return nil
      end
      
      # SQL UTILITY METHODS ======================================#
      
      def get_table_name(sql)
        if sql =~ /^\s*insert\s+into\s+([^\(\s]+)\s*|^\s*update\s+([^\(\s]+)\s*/i
          $1 || $2
        elsif sql =~ /from\s+([^\(\s]+)\s*/i
          $1
        else
          nil
        end
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
          sql.gsub!(/((\.|\s|\()\[?#{col.to_s}\]?)\s?=\s?/, '\1 LIKE ')
          sql.gsub!(/ORDER BY #{col.to_s}/i, '')
        end
        sql
      end

      def get_utf8_columns(table_name)
        utf8 = []
        @table_columns ||= {}
        @table_columns[table_name] ||= columns(table_name)
        @table_columns[table_name].each do |col|
          utf8 << col.name if col.is_utf8
        end
        utf8
      end

      def set_utf8_values!(sql)
        utf8_cols = get_utf8_columns(get_table_name(sql))
        if sql =~ /^\s*UPDATE/i
          utf8_cols.each do |col|
            sql.gsub!("[#{col.to_s}] = '", "[#{col.to_s}] = N'")
          end
        elsif sql =~ /^\s*INSERT(?!.*DEFAULT VALUES\s*$)/i
          # TODO This code should be simplified
          # Get columns and values, split them into arrays, and store the original_values for when we need to replace them
          columns_and_values = sql.scan(/\((.*?)\)/m).flatten
          columns = columns_and_values.first.split(',')
          values =  columns_and_values[1].split(',')
          original_values = values.dup
          # Iterate columns that should be UTF8, and append an N to the value, if the value is not NULL
          utf8_cols.each do |col|
            columns.each_with_index do |column, idx|
              values[idx] = " N#{values[idx].gsub(/^ /, '')}" if column =~ /\[#{col}\]/ and values[idx] !~ /^NULL$/
            end
          end
          # Replace (in place) the SQL
          sql.gsub!(original_values.join(','), values.join(','))
        end
      end
      
    end #class SQLServerAdapter < AbstractAdapter
    
  end #module ConnectionAdapters
  
end #module ActiveRecord

