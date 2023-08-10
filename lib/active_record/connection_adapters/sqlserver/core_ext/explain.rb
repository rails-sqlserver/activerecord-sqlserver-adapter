# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Explain
          SQLSERVER_STATEMENT_PREFIX = "EXEC sp_executesql "
          SQLSERVER_STATEMENT_REGEXP = /N'(.+)', N'(.+)', (.+)/

          def exec_explain(queries, options = [])
            return super unless connection.adapter_name == "SQLServer"

            unprepared_queries = queries.map do |(sql, binds)|
              [unprepare_sqlserver_statement(sql, binds), binds]
            end
            super(unprepared_queries, options)
          end

          private

          # This is somewhat hacky, but it should reliably reformat our prepared sql statement
          # which uses sp_executesql to just the first argument, then unquote it. Likewise our
          # `sp_executesql` method should substitute the @n args with the quoted values.
          def unprepare_sqlserver_statement(sql, binds)
            return sql unless sql.start_with?(SQLSERVER_STATEMENT_PREFIX)

            executesql = sql.from(SQLSERVER_STATEMENT_PREFIX.length)
            executesql = executesql.match(SQLSERVER_STATEMENT_REGEXP).to_a[1]

            binds.each_with_index do |bind, index|

              value = if bind.is_a?(::ActiveModel::Attribute)  then
                connection.quote(bind.value_for_database)
              else
                connection.quote(bind)
              end
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
