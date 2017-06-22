begin
  eval 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
rescue NameError
  begin
    require 'sqljdbc4'
  rescue
    raise("com.microsoft.sqlserver.jdbc.SQLServerDriver not loaded, try installing the sqljdbc4 gem or put the jdbc driver jar in the java CLASSPATH")
  end
end

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Jdbc
        class DatabaseError < StandardError; end

        OPTS = {}.freeze

        # Mutex used to protect mutable data structures
        @data_mutex = Mutex.new

        # Unless in single threaded mode, protects access to any mutable
        # global data structure.
        # Uses a non-reentrant mutex, so calling code should be careful.
        def self.synchronize(&block)
          @data_mutex.synchronize(&block)
        end

        # Make it accesing the java.lang hierarchy more ruby friendly.
        module JavaLang
          include_package 'java.lang'
        end

        # Make it accesing the java.sql hierarchy more ruby friendly.
        module JavaSQL
          include_package 'java.sql'
        end

        # Make it accesing the javax.naming hierarchy more ruby friendly.
        module JavaxNaming
          include_package 'javax.naming'
        end

        # Used to identify a jndi connection and to extract the jndi
        # resource name.
        JNDI_URI_REGEXP = /\Ajdbc:jndi:(.+)/
      end
    end
  end
end

require_relative 'jdbc/database'
require_relative 'jdbc/dataset'
require_relative 'jdbc/type_converter'
