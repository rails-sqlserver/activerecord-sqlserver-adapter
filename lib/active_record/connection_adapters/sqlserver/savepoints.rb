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

        def release_savepoint(_name)
          internal_execute("/* release #{name} savepoint */", "TRANSACTION")
        end
      end
    end
  end
end
