module ActiveRecord
  
  class LostConnection < WrappedDatabaseException
  end
  
  module ConnectionAdapters
    module Sqlserver
      module Errors
        
        LOST_CONNECTION_EXCEPTIONS  = {
          :dblib  => ['TinyTds::Error'],
          :odbc   => ['ODBC::Error','ODBC_UTF8::Error','ODBC_NONE::Error'],
          :adonet => ['TypeError','System::Data::SqlClient::SqlException']
        }.freeze
        
        LOST_CONNECTION_MESSAGES    = {
          :dblib  => [/closed connection/, /dead or not enabled/, /server failed/i],
          :odbc   => [/link failure/, /server failed/, /connection was already closed/, /invalid handle/i],
          :adonet => [/current state is closed/, /network-related/]
        }.freeze
        
        
        def lost_connection_exceptions
          exceptions = LOST_CONNECTION_EXCEPTIONS[@connection_options[:mode]]
          @lost_connection_exceptions ||= exceptions ? exceptions.map{ |e| e.constantize rescue nil }.compact : []
        end
        
        def lost_connection_messages
          LOST_CONNECTION_MESSAGES[@connection_options[:mode]]
        end
        
      end
    end
  end
end
