module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module CoreExt
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
end


ODBC::TimeStamp.send :include, ActiveRecord::ConnectionAdapters::Sqlserver::CoreExt::ODBC::TimeStamp if defined?(ODBC::TimeStamp)
ODBC::Statement.send :include, ActiveRecord::ConnectionAdapters::Sqlserver::CoreExt::ODBC::Statement if defined?(ODBC::Statement)
ODBC::Database.send :include, ActiveRecord::ConnectionAdapters::Sqlserver::CoreExt::ODBC::Database if defined?(ODBC::Database)

