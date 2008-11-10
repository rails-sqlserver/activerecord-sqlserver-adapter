module SQLServerDBI
  module Timestamp
    
    # Will further change DBI's #to_s return value by limiting the usec of the time 
    # to 3 digits and in some cases adding zeros if needed. For example:
    #   "1985-04-15 00:00:00.0"         # => "1985-04-15 00:00:00.000"
    #   "2008-11-08 10:24:36.547000"    # => "2008-11-08 10:24:36.547"
    #   "2008-11-08 10:24:36.123"       # => "2008-11-08 10:24:36.000"
    def to_sqlserver_string
      datetime, usec = to_s[0..22].split('.')
      "#{datetime}.#{sprintf("%03d",usec)}"
    end
    
  end
end

DBI::Timestamp.send :include, SQLServerDBI::Timestamp
