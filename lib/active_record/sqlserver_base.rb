module ActiveRecord
  class Base

    def self.sqlserver_connection(config) #:nodoc:
      config = config.symbolize_keys
      config.reverse_merge! mode: :dblib
      mode = config[:mode].to_s.downcase.underscore.to_sym
      case mode
      when :dblib
        require 'tiny_tds'
      when :odbc
        raise ArgumentError, 'Missing :dsn configuration.' unless config.key?(:dsn)
        require 'odbc'
        require 'active_record/connection_adapters/sqlserver/core_ext/odbc'
      else
        raise ArgumentError, "Unknown connection mode in #{config.inspect}."
      end
      ConnectionAdapters::SQLServerAdapter.new(nil, logger, nil, config.merge(mode: mode))
    end

    # Runs a batch of sql statements with an isolation_level
    #
    # For example:
    #
    #   ActiveRecord::Base.with_isolation_level(:read_uncommitted) do
    #     Posts.where(id: 10).first
    #   end
    #
    # This example will change the select query with :read_uncommitted isolation level
    #
    def self.with_isolation_level(isolation_level)
      old_isolation_level_str = connection.user_options_isolation_level.to_s
      isolation_level_str = connection.transaction_isolation_levels.fetch(isolation_level)
      connection.execute "SET TRANSACTION ISOLATION LEVEL #{isolation_level_str}"
      yield
    ensure
      connection.execute "SET TRANSACTION ISOLATION LEVEL #{old_isolation_level_str}"
    end

  end
end
