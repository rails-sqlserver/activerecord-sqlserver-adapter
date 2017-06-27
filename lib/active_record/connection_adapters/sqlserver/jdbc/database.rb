module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Jdbc
        # logging
        class Database
          # This methods affect relating to the logging of executed SQL.

          # Numeric specifying the duration beyond which queries are logged at warn
          # level instead of info level.
          attr_accessor :log_warn_duration

          # Array of SQL loggers to use for this database.
          attr_accessor :loggers

          # Whether to include information about the connection in use when logging queries.
          attr_accessor :log_connection_info

          # Log level at which to log SQL queries.  This is actually the method
          # sent to the logger, so it should be the method name symbol. The default
          # is :info, it can be set to :debug to log at DEBUG level.
          attr_accessor :sql_log_level

          # Log a message at error level, with information about the exception.
          def log_exception(exception, message)
            log_each(:error, "#{exception.class}: #{exception.message.strip if exception.message}: #{message}")
          end

          # Log a message at level info to all loggers.
          def log_info(message, args=nil)
            log_each(:info, args ? "#{message}; #{args.inspect}" : message)
          end

          # Yield to the block, logging any errors at error level to all loggers,
          # and all other queries with the duration at warn or info level.
          def log_yield(sql, args=nil, &block)
            log_connection_yield(sql, nil, args, &block)
          end

          # Yield to the block, logging any errors at error level to all loggers,
          # and all other queries with the duration at warn or info level.
          def log_connection_yield(sql, conn, args=nil)
            return yield if @loggers.nil? || @loggers.empty?
            sql = "#{connection_info(conn) if conn && log_connection_info}#{sql}#{"; #{args.inspect}" if args}"
            start = Time.now
            begin
              yield
            rescue => e
              log_exception(e, sql)
              raise
            ensure
              log_duration(Time.now - start, sql) unless e
            end
          end

          # Remove any existing loggers and just use the given logger:
          #
          #   DB.logger = Logger.new($stdout)
          def logger=(logger)
            @loggers = Array(logger)
          end

          private

          # String including information about the connection, for use when logging
          # connection info.
          def connection_info(conn)
            "(conn: #{conn.__id__}) "
          end

          # Log message with message prefixed by duration at info level, or
          # warn level if duration is greater than log_warn_duration.
          def log_duration(duration, message)
            log_each((lwd = log_warn_duration and duration >= lwd) ? :warn : sql_log_level, "(#{sprintf('%0.6fs', duration)}) #{message}")
          end

          # Log message at level (which should be :error, :warn, or :info)
          # to all loggers.
          def log_each(level, message)
            @loggers.each{|logger| logger.send(level, message)}
          end
        end

        # connection
        class Database
          # The Java database driver we are using (should be a Java class)
          attr_reader :driver

          # The fetch size to use for JDBC Statement objects created by this database.
          # By default, this is nil so a fetch size is not set explicitly.
          attr_accessor :fetch_size

          attr_reader :opts

          attr_reader :conn

          # Connects to a database.
          def self.connect(conn_string, opts = OPTS)
            opts = {:uri=>conn_string}.merge!(opts)
            # process opts a bit
            opts = opts.inject({}) do |m, (k,v)|
              k = :user if k.to_s == 'username'
              m[k.to_sym] = v
              m
            end
            db = self.new(opts)
            db.connect(opts)
            db
          end

          def initialize(opts)
            @opts = opts
            @loggers = Array(@opts[:logger]) + Array(@opts[:loggers])
            @sql_log_level = @opts[:sql_log_level] ? @opts[:sql_log_level].to_sym : :info
            @default_dataset = Dataset.new(self)
            @driver = com.microsoft.sqlserver.jdbc.SQLServerDriver
            @fetch_size = nil
            self.database_timezone = opts[:database_timezone]
            raise(Error, "No connection string specified") unless uri
          end

          def database_timezone
            opts[:database_timezone]
          end

          def database_timezone=(zone)
            zone = (zone == :local ? :local : :utc)
            opts[:database_timezone] = zone
          end

          # Execute the given stored procedure with the give name. If a block is
          # given, the stored procedure should return rows.
          def call_sproc(name, opts = OPTS)
            args = opts[:args] || []
            sql = "{call #{name}(#{args.map{'?'}.join(',')})}"
            cps = conn.prepareCall(sql)

            args.each_with_index{|arg, i| set_ps_arg(cps, arg, i+1)}

            begin
              case opts[:type]
                when :insert
                  log_connection_yield(sql, conn){cps.executeUpdate}
                  last_insert_id(conn, opts.merge(:prepared => true))
                else
                  log_connection_yield(sql, conn){cps.executeUpdate}
              end
            rescue NativeException, JavaSQL::SQLException => e
              raise e
            ensure
              cps.close
            end
          end

          # Connect to the database using JavaSQL::DriverManager.getConnection.
          def connect(opts)
            conn = if jndi?
              get_connection_from_jndi
            else
              args = [uri(opts)]
              args.concat([opts[:user], opts[:password]]) if opts[:user] && opts[:password]
              begin
                JavaSQL::DriverManager.setLoginTimeout(opts[:login_timeout]) if opts[:login_timeout]
                raise StandardError, "skipping regular connection" if opts[:jdbc_properties]
                JavaSQL::DriverManager.getConnection(*args)
              rescue JavaSQL::SQLException, NativeException, StandardError => e
                raise e unless driver
                # If the DriverManager can't get the connection - use the connect
                # method of the driver. (This happens under Tomcat for instance)
                props = java.util.Properties.new
                if opts && opts[:user] && opts[:password]
                  props.setProperty("user", opts[:user])
                  props.setProperty("password", opts[:password])
                end
                opts[:jdbc_properties].each{|k,v| props.setProperty(k.to_s, v)} if opts[:jdbc_properties]
                begin
                  c = driver.new.connect(args[0], props)
                  raise(Jdbc::DatabaseError, 'driver.new.connect returned nil: probably bad JDBC connection string') unless c
                  c
                rescue JavaSQL::SQLException, NativeException, StandardError => e2
                  if e2.respond_to?(:message=) && e2.message != e.message
                    e2.message = "#{e2.message}\n#{e.class.name}: #{e.message}"
                  end
                  raise e2
                end
              end
            end

            @conn = conn
          end

          def disconnect
            conn.close
          end

          # Execute the given SQL.  If a block is given, if should be a SELECT
          # statement or something else that returns rows.
          def execute(sql, opts=OPTS, &block)
            return call_sproc(sql, opts, &block) if opts[:sproc]

            statement(conn) do |stmt|
              if block
                if size = fetch_size
                  stmt.setFetchSize(size)
                end
                yield log_connection_yield(sql, conn){stmt.executeQuery(sql)}
              else
                case opts[:type]
                  when :ddl
                    log_connection_yield(sql, conn){stmt.execute(sql)}
                  when :insert
                    log_connection_yield(sql, conn){execute_statement_insert(stmt, sql)}
                    last_insert_id(conn, Hash[opts].merge!(:stmt=>stmt))
                  else
                    log_connection_yield(sql, conn){stmt.executeUpdate(sql)}
                end
              end
            end
          end

          # Execute the given DDL SQL, which should not return any
          # values or rows.
          def execute_ddl(sql, opts=OPTS)
            opts = Hash[opts]
            opts[:type] = :ddl
            execute(sql, opts)
          end

          # Execute the given INSERT SQL, returning the last inserted
          # row id.
          def execute_insert(sql, opts=OPTS)
            opts = Hash[opts]
            opts[:type] = :insert
            execute(sql, opts)
          end

          # Whether or not JNDI is being used for this connection.
          def jndi?
            !!(uri =~ JNDI_URI_REGEXP)
          end

          # The uri for this connection.  You can specify the uri
          # using the :uri, :url, or :database options.  You don't
          # need to worry about this if you use connect
          # with the JDBC connectrion strings.
          def uri(opts=OPTS)
            opts = @opts.merge(opts)
            ur = opts[:uri] || opts[:url] || opts[:database]
            ur =~ /^\Ajdbc:/ ? ur : "jdbc:#{ur}"
          end

          # Returns a dataset for the database. The first argument has to be a string
          # calls Database#fetch and returns a dataset for arbitrary SQL.
          #
          # If a block is given, it is used to iterate over the records:
          #
          #   DB.fetch('SELECT * FROM items') {|r| p r}
          #
          # The +fetch+ method returns a dataset instance:
          #
          #   DB.fetch('SELECT * FROM items').all
          #
          # Options can be given as a second argument: {as: :array} to fetch the dataset as an array.
          def fetch(sql, opts=OPTS, &block)
            ds = @default_dataset.with_sql(sql, self.opts.merge(opts))
            ds.each(&block) if block
            ds
          end

          # Runs the supplied SQL statement string on the database server. Returns nil.
          #
          #   DB.run("SET some_server_variable = 42")
          def run(sql)
            execute_ddl(sql)
            nil
          end

          private

          # Execute the insert SQL using the statement
          def execute_statement_insert(stmt, sql)
            stmt.executeUpdate(sql)
          end

          # Gets the connection from JNDI.
          def get_connection_from_jndi
            jndi_name = JNDI_URI_REGEXP.match(uri)[1]
            JavaxNaming::InitialContext.new.lookup(jndi_name).connection
          end

          # Gets the JDBC connection uri from the JNDI resource.
          def get_uri_from_jndi
            conn = get_connection_from_jndi
            conn.meta_data.url
          ensure
            conn.close if conn
          end

          ATAT_IDENTITY = 'SELECT @@IDENTITY'.freeze
          SCOPE_IDENTITY = 'SELECT SCOPE_IDENTITY()'.freeze
          # Get the last inserted id using SCOPE_IDENTITY() or @@IDENTITY.
          def last_insert_id(conn, opts=OPTS)
            statement(conn) do |stmt|
              sql = opts[:prepared] ? ATAT_IDENTITY : SCOPE_IDENTITY
              rs = log_connection_yield(sql, conn){stmt.executeQuery(sql)}
              rs.next
              rs.getLong(1)
            end
          end

          # Java being java, you need to specify the type of each argument
          # for the prepared statement, and bind it individually.  This
          # guesses which JDBC method to use, and hopefully JRuby will convert
          # things properly for us.
          def set_ps_arg(cps, arg, i)
            case arg
              when Integer
                cps.setLong(i, arg)
              #when Sequel::SQL::Blob
              #  cps.setBytes(i, arg.to_java_bytes)
              when String
                cps.setString(i, arg)
              when Float
                cps.setDouble(i, arg)
              when TrueClass, FalseClass
                cps.setBoolean(i, arg)
              when NilClass
                set_ps_arg_nil(cps, i)
              when DateTime
                cps.setTimestamp(i, java_sql_datetime(arg))
              when Date
                cps.setDate(i, java_sql_date(arg))
              when Time
                cps.setTimestamp(i, java_sql_timestamp(arg))
              when Java::JavaSql::Timestamp
                cps.setTimestamp(i, arg)
              when Java::JavaSql::Date
                cps.setDate(i, arg)
              else
                cps.setObject(i, arg)
            end
          end

          # Use setString with a nil value by default, but this doesn't work on all subadapters.
          def set_ps_arg_nil(cps, i)
            cps.setString(i, nil)
          end

          # Yield a new statement object, and ensure that it is closed before returning.
          def statement(conn)
            stmt = conn.createStatement
            yield stmt
          rescue NativeException, JavaSQL::SQLException => e
            raise e
          ensure
            stmt.close if stmt
          end
        end
      end
    end
  end
end
