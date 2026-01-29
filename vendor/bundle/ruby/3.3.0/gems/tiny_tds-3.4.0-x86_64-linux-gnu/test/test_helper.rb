require "bundler"
Bundler.require :development, :test
require "tiny_tds"
require "minitest/autorun"
require "toxiproxy"

require "minitest/reporters"
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new, Minitest::Reporters::JUnitReporter.new]

TINYTDS_SCHEMAS = ["sqlserver_2017", "sqlserver_azure"].freeze

module TinyTds
  class TestCase < Minitest::Spec
    class << self
      def current_schema
        ENV["TINYTDS_SCHEMA"] || "sqlserver_2017"
      end

      TINYTDS_SCHEMAS.each do |schema|
        define_method :"#{schema}?" do
          schema == current_schema
        end
      end
    end

    after { close_client }

    protected

    TINYTDS_SCHEMAS.each do |schema|
      define_method :"#{schema}?" do
        schema == self.class.current_schema
      end
    end

    def current_schema
      self.class.current_schema
    end

    def close_client(client = @client)
      client.close if defined?(client) && client.is_a?(TinyTds::Client)
    end

    def new_connection(options = {})
      client = TinyTds::Client.new(connection_options(options))
      if sqlserver_azure?
        client.execute("SET ANSI_NULLS ON").do
        client.execute("SET CURSOR_CLOSE_ON_COMMIT OFF").do
        client.execute("SET ANSI_NULL_DFLT_ON ON").do
        client.execute("SET IMPLICIT_TRANSACTIONS OFF").do
        client.execute("SET ANSI_PADDING ON").do
        client.execute("SET QUOTED_IDENTIFIER ON").do
        client.execute("SET ANSI_WARNINGS ON").do
      else
        client.execute("SET ANSI_DEFAULTS ON").do
        client.execute("SET CURSOR_CLOSE_ON_COMMIT OFF").do
        client.execute("SET IMPLICIT_TRANSACTIONS OFF").do
      end
      client.execute("SET TEXTSIZE 2147483647").do
      client.execute("SET CONCAT_NULL_YIELDS_NULL ON").do
      client
    end

    def connection_options(options = {})
      username = (sqlserver_azure? ? ENV["TINYTDS_UNIT_AZURE_USER"] : ENV["TINYTDS_UNIT_USER"]) || "tinytds"
      password = (sqlserver_azure? ? ENV["TINYTDS_UNIT_AZURE_PASS"] : ENV["TINYTDS_UNIT_PASS"]) || ""
      {dataserver: sqlserver_azure? ? nil : ENV["TINYTDS_UNIT_DATASERVER"],
       host: ENV["TINYTDS_UNIT_HOST"] || "localhost",
       port: ENV["TINYTDS_UNIT_PORT"] || "1433",
       tds_version: ENV["TINYTDS_UNIT_VERSION"],
       username: username,
       password: password,
       database: ENV["TINYTDS_UNIT_DATABASE"] || "tinytdstest",
       appname: "TinyTds Dev",
       login_timeout: 5,
       timeout: connection_timeout,
       azure: sqlserver_azure?}.merge(options)
    end

    def connection_timeout
      sqlserver_azure? ? 20 : 8
    end

    def assert_client_works(client)
      _(client.execute("SELECT 'client_works' as [client_works]").each).must_equal [{"client_works" => "client_works"}]
    end

    def assert_new_connections_work
      client = new_connection
      client.execute("SELECT 'new_connections_work' as [new_connections_work]").each
      client.close
    end

    def assert_raise_tinytds_error(action)
      result = nil
      error_raised = false
      begin
        result = action.call
      rescue TinyTds::Error => e
        error_raised = true
      end
      assert error_raised, "expected a TinyTds::Error but none happened"
      yield e
    ensure
      close_client(result)
    end

    def inspect_tinytds_exception
      yield
    rescue TinyTds::Error => e
      props = {source: e.source, message: e.message, severity: e.severity,
               db_error_number: e.db_error_number, os_error_number: e.os_error_number}
      raise "TinyTds::Error - #{props.inspect}"
    end

    def assert_binary_encoding(value)
      assert_equal Encoding.find("BINARY"), value.encoding
    end

    def assert_utf8_encoding(value)
      assert_equal Encoding.find("UTF-8"), value.encoding
    end

    def rubyRbx?
      RUBY_DESCRIPTION =~ /rubinius/i
    end

    def ruby_windows?
      RbConfig::CONFIG["host_os"] =~ /ming/
    end

    def ruby_darwin?
      RbConfig::CONFIG["host_os"] =~ /darwin/
    end

    def load_current_schema
      loader = new_connection
      schema_file = File.expand_path File.join(File.dirname(__FILE__), "schema", "#{current_schema}.sql")
      schema_sql = File.open(schema_file, "rb:UTF-8") { |f| f.read }
      loader.execute(drop_sql).do
      loader.execute(schema_sql).do
      loader.execute(sp_sql).do
      loader.execute(sp_error_sql).do
      loader.execute(sp_several_prints_sql).do
      loader.close
      true
    end

    def drop_sql
      %|IF EXISTS (
          SELECT TABLE_NAME
          FROM INFORMATION_SCHEMA.TABLES
          WHERE TABLE_CATALOG = 'tinytdstest'
          AND TABLE_TYPE = 'BASE TABLE'
          AND TABLE_NAME = 'datatypes'
        ) DROP TABLE [datatypes]
        IF EXISTS (
          SELECT name FROM sysobjects
          WHERE name = 'tinytds_TestReturnCodes' AND type = 'P'
        ) DROP PROCEDURE tinytds_TestReturnCodes
        IF EXISTS (
          SELECT name FROM sysobjects
          WHERE name = 'tinytds_TestPrintWithError' AND type = 'P'
        ) DROP PROCEDURE tinytds_TestPrintWithError
        IF EXISTS (
          SELECT name FROM sysobjects
          WHERE name = 'tinytds_TestSeveralPrints' AND type = 'P'
        ) DROP PROCEDURE tinytds_TestSeveralPrints|
    end

    def sp_sql
      %|CREATE PROCEDURE tinytds_TestReturnCodes
        AS
        SELECT 1 as [one]
        RETURN(420) |
    end

    def sp_error_sql
      %|CREATE PROCEDURE tinytds_TestPrintWithError
        AS
        PRINT 'hello'
        RAISERROR('Error following print', 16, 1)|
    end

    def sp_several_prints_sql
      %(CREATE PROCEDURE tinytds_TestSeveralPrints
        AS
        PRINT 'hello 1'
        PRINT 'hello 2'
        PRINT 'hello 3')
    end

    def find_value(id, column, query_options = {})
      query_options[:timezone] ||= :utc
      sql = "SELECT [#{column}] FROM [datatypes] WHERE [id] = #{id}"
      @client.execute(sql).each(query_options).first[column.to_s]
    end

    def local_offset
      TinyTds::Client.local_offset
    end

    def utc_offset
      ::Time.local(2010).utc_offset
    end

    def rollback_transaction(client)
      client.execute("BEGIN TRANSACTION").do
      yield
    ensure
      client.execute("ROLLBACK TRANSACTION").do
    end

    def init_toxiproxy
      # In order for toxiproxy to work for local docker instances of mssql, the containers must be on the same network
      # and the host used below must match the mssql container name so toxiproxy knows where to proxy to.
      # localhost from the perspective of toxiproxy's container is its own container an *not* the mssql container it needs to proxy to.
      # docker-compose.yml handles this automatically for us. In instances where someone is using their own local mssql container they'll
      # need to set up the networks manually and set TINYTDS_UNIT_HOST to their mssql container name
      # For anything other than localhost just use the environment config
      toxi_host = ENV["TOXIPROXY_HOST"] || "localhost"
      toxi_api_port = 8474
      toxi_test_port = 1234
      Toxiproxy.host = "http://#{toxi_host}:#{toxi_api_port}"

      toxi_upstream_host = ENV["TINYTDS_UNIT_HOST_TEST"] || ENV["TINYTDS_UNIT_HOST"] || "localhost"
      toxi_upstream_port = ENV["TINYTDS_UNIT_PORT"] || 1433

      puts "\n-------------------------"
      puts "Toxiproxy api listener: #{toxi_host}:#{toxi_api_port}"
      puts "Toxiproxy unit test listener: #{toxi_host}:#{toxi_test_port}"
      puts "Toxiproxy upstream sqlserver: #{toxi_upstream_host}:#{toxi_upstream_port}"
      puts "-------------------------"

      Toxiproxy.populate([
        {
          name: "sqlserver_test",
          listen: "#{toxi_host}:#{toxi_test_port}",
          upstream: "#{toxi_upstream_host}:#{toxi_upstream_port}"
        }
      ])
    end
  end
end
