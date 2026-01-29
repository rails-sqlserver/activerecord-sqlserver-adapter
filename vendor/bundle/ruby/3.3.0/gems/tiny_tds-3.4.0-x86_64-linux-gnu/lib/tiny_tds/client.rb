module TinyTds
  class Client
    @default_query_options = {
      as: :hash,
      symbolize_keys: false,
      cache_rows: true,
      timezone: :local,
      empty_sets: true
    }

    attr_reader :query_options
    attr_reader :message_handler

    class << self
      attr_reader :default_query_options

      # Most, if not all, iconv encoding names can be found by ruby. Just in case, you can
      # overide this method to return a string name that Encoding.find would work with. Default
      # is to return the passed encoding.
      #
      def transpose_iconv_encoding(encoding)
        encoding
      end

      def local_offset
        ::Time.local(2010).utc_offset.to_r / 86_400
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def initialize(opts = {})
      if opts[:dataserver].to_s.empty? && opts[:host].to_s.empty?
        raise ArgumentError, "missing :host option if no :dataserver given"
      end

      @message_handler = opts[:message_handler]
      if @message_handler && !@message_handler.respond_to?(:call)
        raise ArgumentError, ":message_handler must implement `call` (eg, a Proc or a Method)"
      end

      opts[:username] = parse_username(opts)
      @query_options = self.class.default_query_options.dup
      opts[:password] = opts[:password].to_s if opts[:password] && opts[:password].to_s.strip != ""
      opts[:appname] ||= "TinyTds"
      opts[:tds_version] = tds_versions_setter(opts)
      opts[:use_utf16] = opts[:use_utf16].nil? || ["true", "1", "yes"].include?(opts[:use_utf16].to_s)
      opts[:login_timeout] ||= 60
      opts[:timeout] ||= 5
      opts[:encoding] = (opts[:encoding].nil? || opts[:encoding].casecmp("utf8").zero?) ? "UTF-8" : opts[:encoding].upcase
      opts[:port] ||= 1433
      opts[:dataserver] = "#{opts[:host]}:#{opts[:port]}" if opts[:dataserver].to_s.empty?
      forced_integer_keys = [:login_timeout, :port, :timeout]
      forced_integer_keys.each { |k| opts[k] = opts[k].to_i if opts[k] }
      connect(opts)
    end

    def tds_73?
      tds_version >= 11
    end

    def tds_version_info
      info = TDS_VERSIONS_GETTERS[tds_version]
      "#{info[:name]} - #{info[:description]}" if info
    end

    def active?
      !closed? && !dead?
    end

    private

    def parse_username(opts)
      host = opts[:host]
      username = opts[:username]
      return username if username.nil? || !opts[:azure]
      return username if username.include?("@") && !username.include?("database.windows.net")
      user, domain = username.split("@")
      domain ||= host
      "#{user}@#{domain.split(".").first}"
    end

    def tds_versions_setter(opts = {})
      v = opts[:tds_version] || ENV["TDSVER"] || "7.3"
      TDS_VERSIONS_SETTERS[v.to_s]
    end

    # From sybdb.h comments:
    # DBVERSION_xxx are used with dbsetversion()
    #
    TDS_VERSIONS_SETTERS = {
      "unknown" => 0,
      "46" => 1,
      "100" => 2,
      "42" => 3,
      "70" => 4,
      "7.0" => 4,
      "71" => 5,
      "7.1" => 5,
      "80" => 5,
      "8.0" => 5,
      "72" => 6,
      "7.2" => 6,
      "90" => 6,
      "9.0" => 6,
      "73" => 7,
      "7.3" => 7
    }.freeze

    # From sybdb.h comments:
    # DBTDS_xxx are returned by DBTDS()
    # The integer values of the constants are poorly chosen.
    #
    TDS_VERSIONS_GETTERS = {
      0 => {name: "DBTDS_UNKNOWN", description: "Unknown"},
      1 => {name: "DBTDS_2_0", description: "Pre 4.0 SQL Server"},
      2 => {name: "DBTDS_3_4", description: "Microsoft SQL Server (3.0)"},
      3 => {name: "DBTDS_4_0", description: "4.0 SQL Server"},
      4 => {name: "DBTDS_4_2", description: "4.2 SQL Server"},
      5 => {name: "DBTDS_4_6", description: "2.0 OpenServer and 4.6 SQL Server."},
      6 => {name: "DBTDS_4_9_5", description: "4.9.5 (NCR) SQL Server"},
      7 => {name: "DBTDS_5_0", description: "5.0 SQL Server"},
      8 => {name: "DBTDS_7_0", description: "Microsoft SQL Server 7.0"},
      9 => {name: "DBTDS_7_1/DBTDS_8_0", description: "Microsoft SQL Server 2000"},
      10 => {name: "DBTDS_7_2/DBTDS_9_0", description: "Microsoft SQL Server 2005"},
      11 => {name: "DBTDS_7_3", description: "Microsoft SQL Server 2008"},
      12 => {name: "DBTDS_7_4", description: "Microsoft SQL Server 2012/2014"}
    }.freeze
  end
end
