# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module Savepoints
        def current_savepoint_name
          current_transaction.savepoint_name
        end

        def create_savepoint(name = current_savepoint_name)
          internal_execute("SAVE TRANSACTION #{name}", "TRANSACTION")
        end

        def exec_rollback_to_savepoint(name = current_savepoint_name)
          internal_execute("ROLLBACK TRANSACTION #{name}", "TRANSACTION")
        end

        # SQL Server does require save-points to be explicitly released.
        # See https://stackoverflow.com/questions/3101312/sql-server-2008-no-release-savepoint-for-current-transaction
        def release_savepoint(_name)
        end
      end
    end
  end
end
