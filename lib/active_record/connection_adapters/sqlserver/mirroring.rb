module ActiveRecord
  class Base
    def self.db_mirroring_status

      #Returns hash with db mirroring status details
      #  if mirroring is inactive for current database returns empty hash
      connection.select_one("
          SELECT 
              DB_NAME(database_id) database_name
            , mirroring_role_desc 
            , mirroring_safety_level_desc
            , mirroring_state_desc
            , mirroring_safety_sequence
            , mirroring_role_sequence
            , mirroring_partner_instance
            , mirroring_witness_name
            , mirroring_witness_state_desc
            , mirroring_failover_lsn
         FROM sys.database_mirroring
         WHERE mirroring_guid IS NOT NULL
       	   and database_id = db_id(); 
        ") || {}
    end
    
    #Returns true if current database is db mirroring principal
    def self.db_mirroring_active?
      db_mirroring_status["mirroring_role_desc"] == "PRINCIPAL"
    end

    #Returns true if db mirroring is in synchronized state
    def self.db_mirroring_synchronized?
      db_mirroring_status["mirroring_state_desc"] == "SYNCHRONIZED"
    end
    
    #Returns current database server name
    def self.server_name
      connection.select_value("select @@servername")
    end

  end
end

module ActiveRecord
  module ConnectionAdapters

    module SqlServerMirroring

      protected

      def mirror_defined?
        !@connection_options[:mirror].nil?
      end
      
      def switch_to_mirror
        @connection_options[:mirror].each_key do |key|
          tmp = @connection_options[:mirror][key]
          @connection_options[:mirror][key] = @connection_options[key.to_sym] || @connection_options[key]
          @connection_options[key.to_sym] = tmp
          @connection_options[key] = tmp
        end
      end      

    end

    class SQLServerAdapter
      include ActiveRecord::ConnectionAdapters::SqlServerMirroring
      
      def connect_with_mirroring
        return connect_without_mirroring unless mirror_defined?
        connect_without_mirroring rescue connect_to_mirror
        connect_to_mirror if @auto_connecting && !active?
        @connection
      end            

      alias_method_chain :connect, :mirroring
      
      private 

      def connect_to_mirror
        switch_to_mirror
        connect_without_mirroring        
      end

    end
  end
end
