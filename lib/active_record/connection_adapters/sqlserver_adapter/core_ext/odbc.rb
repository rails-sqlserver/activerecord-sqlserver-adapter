
module ActiveRecord
  module ConnectionAdapters
    module SQLServerCoreExtensions
      module ODBC
        module TimeStamp
          def to_sqlserver_string
            date, time, nanoseconds = to_s.split(' ')
            "#{date} #{time}.#{sprintf("%03d",nanoseconds.to_i/1000000)}"
          end
        end
        
        module Statement
          def finished?
            begin
              connected?
              false
            rescue ::ODBC::Error => e
              true
            end
          end
          
        end

        module Database
          def run_block(*args)
            yield sth = run(*args)
            sth.drop
          end
        end
      end
    end
  end
end

if defined?(ODBC::TimeStamp)
  ODBC::TimeStamp.send :include, ActiveRecord::ConnectionAdapters::SQLServerCoreExtensions::ODBC::TimeStamp
end
if defined?(ODBC::Statement)
  ODBC::Statement.send :include, ActiveRecord::ConnectionAdapters::SQLServerCoreExtensions::ODBC::Statement
end
if defined?(ODBC::Database)
  ODBC::Database.send :include, ActiveRecord::ConnectionAdapters::SQLServerCoreExtensions::ODBC::Database
end