module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module CoreExt
        module Relation
          private

          def tables_in_string(string)
            super - ['__rnt']
          end
        end
      end
    end
  end
end

ActiveRecord::Relation.send :include, ActiveRecord::ConnectionAdapters::SQLServer::CoreExt::Relation
