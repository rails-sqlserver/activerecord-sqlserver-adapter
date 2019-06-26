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

        NativeException = java.lang.Exception
             
        # Default database error classes
        DATABASE_ERROR_CLASSES = [NativeException].freeze
        if JRUBY_VERSION < '9.2'
         # On JRuby <9.2, still include ::NativeException, as it is still needed in some cases
         DATABASE_ERROR_CLASSES << ::NativeException
        end
        DATABASE_ERROR_CLASSES.freeze

        OPTS = {}.freeze

        # Make it accessing the java.sql hierarchy more ruby friendly.
        module JavaSQL
          include_package 'java.sql'
        end

        # Make it accessing the javax.naming hierarchy more ruby friendly.
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
