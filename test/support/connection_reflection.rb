module ARTest
  module SQLServer
    module ConnectionReflection

      extend ActiveSupport::Concern

      included { extend ConnectionReflection }

      def connection
        ActiveRecord::Base.connection
      end

      def connection_options
        connection.instance_variable_get :@connection_options
      end

      def connection_dblib?
        connection_options[:mode] == :dblib
      end

      def connection_dblib_73?
        return false unless connection_dblib?
        rc = connection.raw_connection
        rc.respond_to?(:tds_73?) && rc.tds_73?
      end

      def connection_odbc?
        connection_options[:mode] == :odbc
      end

      def connection_sqlserver_azure?
        connection.sqlserver_azure?
      end

    end
  end
end
