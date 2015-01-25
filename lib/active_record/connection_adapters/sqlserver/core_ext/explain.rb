module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Explain

          SQLSERVER_STATEMENT_PREFIX = 'EXEC sp_executesql '
          SQLSERVER_PARAM_MATCHER = /@\d+ =/

          def exec_explain(queries)
            unprepared_queries = queries.map { |sql, bind| [unprepare_sqlserver_statement(sql), bind] }
            super(unprepared_queries)
          end

          private

          # This is somewhat hacky, but it should reliably reformat our prepared sql statment
          # which uses sp_executesql to just the first argument, then unquote it. Likewise our
          # `sp_executesql` method should substitude the @n args withe the quoted values.
          def unprepare_sqlserver_statement(sql)
            if sql.starts_with?(SQLSERVER_STATEMENT_PREFIX)
              executesql = sql.from(SQLSERVER_STATEMENT_PREFIX.length)
              executesql_args = executesql.split(', ')
              found_args = executesql_args.reject! { |arg| arg =~ SQLSERVER_PARAM_MATCHER }
              executesql_args.pop if found_args && executesql_args.many?
              executesql = executesql_args.join(', ').strip.match(/N'(.*)'/m)[1]
              Utils.unquote_string(executesql)
            else
              sql
            end
          end

        end
      end
    end
  end
end

ActiveRecord::Base.extend ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::Explain
ActiveRecord::Relation.send :include, ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::Explain
