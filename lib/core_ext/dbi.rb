
module SQLServerDBI
  
  module Timestamp
    # Will further change DBI::Timestamp #to_s return value by limiting the usec of 
    # the time to 3 digits and in some cases adding zeros if needed. For example:
    #   "1985-04-15 00:00:00.0"         # => "1985-04-15 00:00:00.000"
    #   "2008-11-08 10:24:36.547000"    # => "2008-11-08 10:24:36.547"
    #   "2008-11-08 10:24:36.123"       # => "2008-11-08 10:24:36.000"
    def to_sqlserver_string
      datetime, usec = to_s[0..22].split('.')
      "#{datetime}.#{sprintf("%03d",usec)}"
    end
  end
  
      
  module Type
    
    # Make sure we get DBI::Type::Timestamp returning a string NOT a time object
    # that represents what is in the DB before type casting and let the adapter 
    # do the reset. DBI::DBD::ODBC will typically return a string like:
    #   "1985-04-15 00:00:00 0"           # => "1985-04-15 00:00:00.000"
    #   "2008-11-08 10:24:36 547000000"   # => "2008-11-08 10:24:36.547"
    #   "2008-11-08 10:24:36 123000000"   # => "2008-11-08 10:24:36.000"
    class SqlserverTimestamp
      def self.parse(obj)
        return nil if ::DBI::Type::Null.parse(obj).nil?
        date, time, fraction = obj.split(' ')
        "#{date} #{time}.#{sprintf("%03d",fraction)}"
      end
    end
    
    # The adapter and rails will parse our floats, decimals, and money field correctly 
    # from a string. Do not let the DBI::Type classes create Float/BigDecimal objects 
    # for us. Trust rails .type_cast to do what it is built to do.
    class SqlserverForcedString
      def self.parse(obj)
        return nil if ::DBI::Type::Null.parse(obj).nil?
        obj.to_s
      end
    end
    
  end
  
  module TypeUtil
    
    def self.included(klass)
      klass.extend ClassMethods
      class << klass
        alias_method_chain :type_name_to_module, :sqlserver_types
      end
    end
    
    module ClassMethods
      
      # Capture all types classes that we need to handle directly for SQL Server 
      # and allow normal processing for those that we do not.
      def type_name_to_module_with_sqlserver_types(type_name)
        case type_name
        when /^timestamp$/i
          DBI::Type::SqlserverTimestamp
        when /^float|decimal|money$/i
          DBI::Type::SqlserverForcedString
        else
          type_name_to_module_without_sqlserver_types(type_name)
        end
      end
      
    end
    
  end
  
  
end


if defined?(DBI::TypeUtil)
  DBI::Type.send :include, SQLServerDBI::Type
  DBI::TypeUtil.send :include, SQLServerDBI::TypeUtil
elsif defined?(DBI::Timestamp) # DEPRECATED in DBI 0.4.0 and above. Remove when 0.2.2 and lower is no longer supported.
  DBI::Timestamp.send :include, SQLServerDBI::Timestamp
end

