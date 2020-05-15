# frozen_string_literal: true

require "active_record/relation"
require "active_record/version"

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module QueryMethods
          private

          # Copy of original from Rails master.
          # This patch can be removed when adapter supports Rails version greater than 6.0.2.2
          def table_name_matches?(from)
            table_name = Regexp.escape(table.name)
            quoted_table_name = Regexp.escape(connection.quote_table_name(table.name))
            /(?:\A|(?<!FROM)\s)(?:\b#{table_name}\b|#{quoted_table_name})(?!\.)/i.match?(from.to_s)
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.include(ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::QueryMethods)
end
