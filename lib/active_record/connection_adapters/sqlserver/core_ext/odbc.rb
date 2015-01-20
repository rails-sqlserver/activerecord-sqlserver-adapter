module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module ODBC

          module Statement

            def finished?
              connected?
              false
            rescue ::ODBC::Error
              true
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

ODBC::Statement.send :include, ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::ODBC::Statement
ODBC::Database.send :include, ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::ODBC::Database
