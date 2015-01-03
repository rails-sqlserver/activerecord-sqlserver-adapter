module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Version

        VERSION = '4.2.0'

        SUPPORTED_VERSIONS = [2005, 2008, 2010, 2011, 2012, 2014]
        DATABASE_VERSION_REGEXP = /Microsoft SQL Server\s+"?(\d{4}|\w+)"?/

      end
    end
  end
end
