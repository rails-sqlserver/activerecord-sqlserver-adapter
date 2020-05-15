# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Explain
          SQLSERVER_STATEMENT_PREFIX = "EXEC sp_executesql "
          SQLSERVER_STATEMENT_REGEXP = /N'(.+)', N'(.+)', (.+)/

          def exec_explain(queries)
            unprepared_queries = queries.map do |(sql, binds)|
              [unprepare_sqlserver_statement(sql, binds), binds]
            end
            super(unprepared_queries)
          end

          private

          # This is somewhat hacky, but it should reliably reformat our prepared sql statment
          # which uses sp_executesql to just the first argument, then unquote it. Likewise our
          # `sp_executesql` method should substitude the @n args with the quoted values.
          def unprepare_sqlserver_statement(sql, binds)
            return sql unless sql.starts_with?(SQLSERVER_STATEMENT_PREFIX)

            executesql = sql.from(SQLSERVER_STATEMENT_PREFIX.length)
            executesql = executesql.match(SQLSERVER_STATEMENT_REGEXP).to_a[1]

            binds.each_with_index do |bind, index|
              value = connection.quote(bind)
              executesql = executesql.sub("@#{index}", value)
            end

            executesql
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
