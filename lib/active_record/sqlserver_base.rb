# frozen_string_literal: true

module ActiveRecord
  module ConnectionHandling
    def sqlserver_connection_class
      ConnectionAdapters::SQLServerAdapter
    end

    def sqlserver_connection(config) #:nodoc:
      config = config.symbolize_keys
      config.reverse_merge!(mode: :dblib)
      config[:mode] = config[:mode].to_s.downcase.underscore.to_sym

      sqlserver_connection_class.new(
        sqlserver_connection_class.new_client(config),
        logger,
        nil,
        config
        )
    end
  end
end
