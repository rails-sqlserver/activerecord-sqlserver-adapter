# frozen_string_literal: true

module ActiveRecord
  module ConnectionHandling
    def sqlserver_adapter_class
      ConnectionAdapters::SQLServerAdapter
    end

    def sqlserver_connection(config) #:nodoc:
      sqlserver_adapter_class.new(config)
    end
  end
end
