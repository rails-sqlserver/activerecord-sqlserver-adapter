module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Explain

          SQLSERVER_STATEMENT_PREFIX = 'EXEC sp_executesql '.freeze
          SQLSERVER_PARAM_MATCHER = /@\d+ = (.*)/
          SQLSERVER_NATIONAL_STRING_MATCHER = /N'(.*)'/m

          def exec_explain(queries)
            unprepared_queries = queries.map do |(sql, binds)|
              [unprepare_sqlserver_statement(sql), binds]
            end
            super(unprepared_queries)
          end

          private

          # This is somewhat hacky, but it should reliably reformat our prepared sql statment
          # which uses sp_executesql to just the first argument, then unquote it. Likewise our
          # `sp_executesql` method should substitude the @n args withe the quoted values.
          def unprepare_sqlserver_statement(sql)
            if sql.starts_with?(SQLSERVER_STATEMENT_PREFIX)
              executesql = sql.from(SQLSERVER_STATEMENT_PREFIX.length)
              args = executesql.split(', ')
              unprepared_sql = args.shift.strip.match(SQLSERVER_NATIONAL_STRING_MATCHER)[1]
              unprepared_sql = Utils.unquote_string(unprepared_sql)
              args = args.from(args.length / 2)
              args.each_with_index do |arg, index|
                value = arg.match(SQLSERVER_PARAM_MATCHER)[1]
                unprepared_sql.sub! "@#{index}", value
              end
              unprepared_sql
            else
              sql
            end
          end

        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  extend ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::Explain
  ActiveRecord::Relation.include(ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::Explain)
end
