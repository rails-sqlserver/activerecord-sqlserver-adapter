# frozen_string_literal: true

require "active_record/connection_adapters/abstract/transaction"

module ActiveRecord
  module ConnectionAdapters
    module SQLServerTransaction
      delegate :sqlserver?, to: :connection, prefix: true

      private

      def current_isolation_level
        return unless connection_sqlserver?

        level = connection.user_options_isolation_level
        # When READ_COMMITTED_SNAPSHOT is set to ON,
        # user_options_isolation_level will be equal to 'read committed
        # snapshot' which is not a valid isolation level
        if level.blank? || level == "read committed snapshot"
          "READ COMMITTED"
        else
          level.upcase
        end
      end
    end

    Transaction.send :prepend, SQLServerTransaction

    module SQLServerRealTransaction
      attr_reader :starting_isolation_level

      def initialize(connection, isolation: nil, joinable: true, run_commit_callbacks: false)
        @connection = connection
        @starting_isolation_level = current_isolation_level if isolation
        super
      end

      def commit
        super
        reset_starting_isolation_level
      end

      def rollback
        super
        reset_starting_isolation_level
      end

      private

      def reset_starting_isolation_level
        if connection_sqlserver? && starting_isolation_level
          connection.set_transaction_isolation_level(starting_isolation_level)
        end
      end
    end

    RealTransaction.send :prepend, SQLServerRealTransaction
  end
end
