# frozen_string_literal: true

require "base64"
require "active_record"
require "arel_sqlserver"
require "active_record/connection_adapters/abstract_adapter"
require "active_record/connection_adapters/sqlserver/core_ext/active_record"
require "active_record/connection_adapters/sqlserver/core_ext/calculations"
require "active_record/connection_adapters/sqlserver/core_ext/explain"
require "active_record/connection_adapters/sqlserver/core_ext/explain_subscriber"
require "active_record/connection_adapters/sqlserver/core_ext/attribute_methods"
require "active_record/connection_adapters/sqlserver/core_ext/finder_methods"
require "active_record/connection_adapters/sqlserver/core_ext/query_methods"
require "active_record/connection_adapters/sqlserver/core_ext/preloader"
require "active_record/connection_adapters/sqlserver/version"
require "active_record/connection_adapters/sqlserver/type"
require "active_record/connection_adapters/sqlserver/database_limits"
require "active_record/connection_adapters/sqlserver/database_statements"
require "active_record/connection_adapters/sqlserver/database_tasks"
require "active_record/connection_adapters/sqlserver/transaction"
require "active_record/connection_adapters/sqlserver/errors"
require "active_record/connection_adapters/sqlserver/schema_creation"
require "active_record/connection_adapters/sqlserver/schema_dumper"
require "active_record/connection_adapters/sqlserver/schema_statements"
require "active_record/connection_adapters/sqlserver/sql_type_metadata"
require "active_record/connection_adapters/sqlserver/showplan"
require "active_record/connection_adapters/sqlserver/table_definition"
require "active_record/connection_adapters/sqlserver/quoting"
require "active_record/connection_adapters/sqlserver/utils"
require "active_record/sqlserver_base"
require "active_record/connection_adapters/sqlserver_column"
require "active_record/tasks/sqlserver_database_tasks"

module ActiveRecord
  module ConnectionAdapters
    class SQLServerAdapter < AbstractAdapter
      include SQLServer::Version,
              SQLServer::Quoting,
              SQLServer::DatabaseStatements,
              SQLServer::Showplan,
              SQLServer::SchemaStatements,
              SQLServer::DatabaseLimits,
              SQLServer::DatabaseTasks

      ADAPTER_NAME = "SQLServer".freeze

      # Default precision for 'time' (See https://docs.microsoft.com/en-us/sql/t-sql/data-types/time-transact-sql)
      DEFAULT_TIME_PRECISION = 7

      attr_reader :spid

      cattr_accessor :cs_equality_operator, instance_accessor: false
      cattr_accessor :use_output_inserted, instance_accessor: false
      cattr_accessor :exclude_output_inserted_table_names, instance_accessor: false
      cattr_accessor :showplan_option, instance_accessor: false
      cattr_accessor :lowercase_schema_reflection

      self.cs_equality_operator = "COLLATE Latin1_General_CS_AS_WS"
      self.use_output_inserted = true
      self.exclude_output_inserted_table_names = Concurrent::Map.new { false }

      def initialize(connection, logger = nil, config = {})
        super(connection, logger, config)
        # Our Responsibility
        @connection_options = config
        connect
        initialize_dateformatter
        use_database
      end

      # === Abstract Adapter ========================================== #

      def arel_visitor
        Arel::Visitors::SQLServer.new self
      end

      def valid_type?(type)
        !native_database_types[type].nil?
      end

      def schema_creation
        SQLServer::SchemaCreation.new self
      end

      def self.database_exists?(config)
        !!ActiveRecord::Base.sqlserver_connection(config)
      rescue ActiveRecord::NoDatabaseError
        false
      end

      def supports_ddl_transactions?
        true
      end

      def supports_bulk_alter?
        false
      end

      def supports_advisory_locks?
        false
      end

      def supports_index_sort_order?
        true
      end

      def supports_partial_index?
        true
      end

      def supports_expression_index?
        false
      end

      def supports_explain?
        true
      end

      def supports_transaction_isolation?
        true
      end

      def supports_indexes_in_create?
        false
      end

      def supports_foreign_keys?
        true
      end

      def supports_views?
        true
      end

      def supports_datetime_with_precision?
        true
      end

      def supports_json?
        @version_year >= 2016
      end

      def supports_comments?
        false
      end

      def supports_comments_in_create?
        false
      end

      def supports_savepoints?
        true
      end

      def supports_lazy_transactions?
        true
      end

      def supports_in_memory_oltp?
        @version_year >= 2014
      end

      def supports_insert_returning?
        true
      end

      def supports_insert_on_duplicate_skip?
        false
      end

      def supports_insert_on_duplicate_update?
        false
      end

      def supports_insert_conflict_target?
        false
      end

      def disable_referential_integrity
        tables = tables_with_referential_integrity
        tables.each { |t| do_execute "ALTER TABLE #{quote_table_name(t)} NOCHECK CONSTRAINT ALL" }
        yield
      ensure
        tables.each { |t| do_execute "ALTER TABLE #{quote_table_name(t)} CHECK CONSTRAINT ALL" }
      end

      # === Abstract Adapter (Connection Management) ================== #

      def active?
        return false unless @connection

        raw_connection_do "SELECT 1"
        true
      rescue *connection_errors
        false
      end

      def reconnect!
        super
        disconnect!
        connect
      end

      def disconnect!
        super
        case @connection_options[:mode]
        when :dblib
          @connection.close rescue nil
        end
        @connection = nil
        @spid = nil
        @collation = nil
      end

      def clear_cache!
        @view_information = nil
        super
      end

      def reset!
        reset_transaction
        do_execute "IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION"
      end

      # === Abstract Adapter (Misc Support) =========================== #

      def tables_with_referential_integrity
        schemas_and_tables = select_rows <<~SQL.squish
          SELECT DISTINCT s.name, o.name
          FROM sys.foreign_keys i
          INNER JOIN sys.objects o ON i.parent_object_id = o.OBJECT_ID
          INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
        SQL
        schemas_and_tables.map do |schema_table|
          schema, table = schema_table
          "#{SQLServer::Utils.quoted_raw(schema)}.#{SQLServer::Utils.quoted_raw(table)}"
        end
      end

      def pk_and_sequence_for(table_name)
        pk = primary_key(table_name)
        pk ? [pk, nil] : nil
      end

      # === SQLServer Specific (DB Reflection) ======================== #

      def sqlserver?
        true
      end

      def sqlserver_azure?
        !!(sqlserver_version =~ /Azure/i)
      end

      def database_prefix_remote_server?
        return false if database_prefix.blank?

        name = SQLServer::Utils.extract_identifiers(database_prefix)
        name.fully_qualified? && name.object.blank?
      end

      def database_prefix
        @connection_options[:database_prefix]
      end

      def database_prefix_identifier(name)
        if database_prefix_remote_server?
          SQLServer::Utils.extract_identifiers("#{database_prefix}#{name}")
        else
          SQLServer::Utils.extract_identifiers(name)
        end
      end

      def version
        self.class::VERSION
      end

      def inspect
        "#<#{self.class} version: #{version}, mode: #{@connection_options[:mode]}, azure: #{sqlserver_azure?.inspect}>"
      end

      def combine_bind_parameters(from_clause: [], join_clause: [], where_clause: [], having_clause: [], limit: nil, offset: nil)
        result = from_clause + join_clause + where_clause + having_clause
        result << offset if offset
        result << limit if limit
        result
      end

      def get_database_version # :nodoc:
        version_year
      end

      protected

      # === Abstract Adapter (Misc Support) =========================== #

      def initialize_type_map(m = type_map)
        m.register_type              %r{.*}, SQLServer::Type::UnicodeString.new
        # Exact Numerics
        register_class_with_limit m, "bigint(8)",         SQLServer::Type::BigInteger
        m.alias_type                 "bigint",            "bigint(8)"
        register_class_with_limit m, "int(4)",            SQLServer::Type::Integer
        m.alias_type                 "integer",           "int(4)"
        m.alias_type                 "int",               "int(4)"
        register_class_with_limit m, "smallint(2)",       SQLServer::Type::SmallInteger
        m.alias_type                 "smallint",          "smallint(2)"
        register_class_with_limit m, "tinyint(1)",        SQLServer::Type::TinyInteger
        m.alias_type                 "tinyint",           "tinyint(1)"
        m.register_type              "bit",               SQLServer::Type::Boolean.new
        m.register_type              %r{\Adecimal}i do |sql_type|
          scale = extract_scale(sql_type)
          precision = extract_precision(sql_type)
          SQLServer::Type::Decimal.new precision: precision, scale: scale
        end
        m.alias_type                 %r{\Anumeric}i,      "decimal"
        m.register_type              "money",             SQLServer::Type::Money.new
        m.register_type              "smallmoney",        SQLServer::Type::SmallMoney.new
        # Approximate Numerics
        m.register_type              "float",             SQLServer::Type::Float.new
        m.register_type              "real",              SQLServer::Type::Real.new
        # Date and Time
        m.register_type              "date",              SQLServer::Type::Date.new
        m.register_type              %r{\Adatetime} do |sql_type|
          precision = extract_precision(sql_type)
          if precision
            SQLServer::Type::DateTime2.new precision: precision
          else
            SQLServer::Type::DateTime.new
          end
        end
        m.register_type %r{\Adatetimeoffset}i do |sql_type|
          precision = extract_precision(sql_type)
          SQLServer::Type::DateTimeOffset.new precision: precision
        end
        m.register_type              "smalldatetime", SQLServer::Type::SmallDateTime.new
        m.register_type              %r{\Atime}i do |sql_type|
          precision = extract_precision(sql_type) || DEFAULT_TIME_PRECISION
          SQLServer::Type::Time.new precision: precision
        end
        # Character Strings
        register_class_with_limit m, %r{\Achar}i,         SQLServer::Type::Char
        register_class_with_limit m, %r{\Avarchar}i,      SQLServer::Type::Varchar
        m.register_type              "varchar(max)",      SQLServer::Type::VarcharMax.new
        m.register_type              "text",              SQLServer::Type::Text.new
        # Unicode Character Strings
        register_class_with_limit m, %r{\Anchar}i,        SQLServer::Type::UnicodeChar
        register_class_with_limit m, %r{\Anvarchar}i,     SQLServer::Type::UnicodeVarchar
        m.alias_type                 "string",            "nvarchar(4000)"
        m.register_type              "nvarchar(max)",     SQLServer::Type::UnicodeVarcharMax.new
        m.register_type              "nvarchar(max)",     SQLServer::Type::UnicodeVarcharMax.new
        m.register_type              "ntext",             SQLServer::Type::UnicodeText.new
        # Binary Strings
        register_class_with_limit m, %r{\Abinary}i,       SQLServer::Type::Binary
        register_class_with_limit m, %r{\Avarbinary}i,    SQLServer::Type::Varbinary
        m.register_type              "varbinary(max)",    SQLServer::Type::VarbinaryMax.new
        # Other Data Types
        m.register_type              "uniqueidentifier",  SQLServer::Type::Uuid.new
        m.register_type              "timestamp",         SQLServer::Type::Timestamp.new
      end

      def translate_exception(e, message:, sql:, binds:)
        case message
        when /(cannot insert duplicate key .* with unique index) | (violation of unique key constraint)/i
          RecordNotUnique.new(message, sql: sql, binds: binds)
        when /(conflicted with the foreign key constraint) | (The DELETE statement conflicted with the REFERENCE constraint)/i
          InvalidForeignKey.new(message, sql: sql, binds: binds)
        when /has been chosen as the deadlock victim/i
          DeadlockVictim.new(message, sql: sql, binds: binds)
        when /database .* does not exist/i
          NoDatabaseError.new(message, sql: sql, binds: binds)
        when /data would be truncated/
          ValueTooLong.new(message, sql: sql, binds: binds)
        when /connection timed out/
          StatementTimeout.new(message, sql: sql, binds: binds)
        when /Column '(.*)' is not the same data type as referencing column '(.*)' in foreign key/
          pk_id, fk_id = SQLServer::Utils.extract_identifiers($1), SQLServer::Utils.extract_identifiers($2)
          MismatchedForeignKey.new(
            self,
            message: message,
            table: fk_id.schema,
            foreign_key: fk_id.object,
            target_table: pk_id.schema,
            primary_key: pk_id.object
          )
        when /Cannot insert the value NULL into column.*does not allow nulls/
          NotNullViolation.new(message, sql: sql, binds: binds)
        when /Arithmetic overflow error/
          RangeError.new(message, sql: sql, binds: binds)
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
                      end
        @spid = _raw_select("SELECT @@SPID", fetch: :rows).first.first
        @version_year = version_year
        configure_connection
      end

      def connection_errors
        @connection_errors ||= [].tap do |errors|
          errors << TinyTds::Error if defined?(TinyTds::Error)
        end
      end

      def dblib_connect(config)
        TinyTds::Client.new(
          dataserver: config[:dataserver],
          host: config[:host],
          port: config[:port],
          username: config[:username],
          password: config[:password],
          database: config[:database],
          tds_version: config[:tds_version] || "7.3",
          appname: config_appname(config),
          login_timeout: config_login_timeout(config),
          timeout: config_timeout(config),
          encoding: config_encoding(config),
          azure: config[:azure],
          contained: config[:contained]
        ).tap do |client|
          if config[:azure]
            client.execute("SET ANSI_NULLS ON").do
            client.execute("SET ANSI_NULL_DFLT_ON ON").do
            client.execute("SET ANSI_PADDING ON").do
            client.execute("SET ANSI_WARNINGS ON").do
          else
            client.execute("SET ANSI_DEFAULTS ON").do
          end
          client.execute("SET QUOTED_IDENTIFIER ON").do
          client.execute("SET CURSOR_CLOSE_ON_COMMIT OFF").do
          client.execute("SET IMPLICIT_TRANSACTIONS OFF").do
          client.execute("SET TEXTSIZE 2147483647").do
          client.execute("SET CONCAT_NULL_YIELDS_NULL ON").do
        end
      end

      def config_appname(config)
        config[:appname] || configure_application_name || Rails.application.class.name.split("::").first rescue nil
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

      def configure_connection; end

      def configure_application_name; end

      def initialize_dateformatter
        @database_dateformat = user_options_dateformat
        a, b, c = @database_dateformat.each_char.to_a
        [a, b, c].each { |f| f.upcase! if f == "y" }
        dateformat = "%#{a}-%#{b}-%#{c}"
        ::Date::DATE_FORMATS[:_sqlserver_dateformat]     = dateformat
        ::Time::DATE_FORMATS[:_sqlserver_dateformat]     = dateformat
        ::Time::DATE_FORMATS[:_sqlserver_time]           = "%H:%M:%S"
        ::Time::DATE_FORMATS[:_sqlserver_datetime]       = "#{dateformat} %H:%M:%S"
        ::Time::DATE_FORMATS[:_sqlserver_datetimeoffset] = lambda { |time|
          time.strftime "#{dateformat} %H:%M:%S.%9N #{time.formatted_offset}"
        }
      end

      def version_year
        return 2016 if sqlserver_version =~ /vNext/

        /SQL Server (\d+)/.match(sqlserver_version).to_a.last.to_s.to_i
      rescue StandardError
        2016
      end

      def sqlserver_version
        @sqlserver_version ||= _raw_select("SELECT @@version", fetch: :rows).first.first.to_s
      end
    end
  end
end
