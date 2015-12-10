module ActiveRecord
  module ConnectionHandling
    def sqlserver_connection(config) #:nodoc:
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
  end
end
