require 'active_record/connection_adapters/abstract/transaction'

module ActiveRecord
  module ConnectionAdapters

    module SQLServerTransaction

      private

      def sqlserver?
        connection.respond_to?(:sqlserver?) && connection.sqlserver?
      end

      def current_isolation_level
        return unless sqlserver?
        level = connection.user_options_isolation_level
        level.blank? ? 'READ COMMITTED' : level.upcase
      end

    end

    Transaction.send :include, SQLServerTransaction

    module SQLServerRealTransaction

      attr_reader :starting_isolation_level

      def initialize(connection, options)
        @connection = connection
        @starting_isolation_level = current_isolation_level if options[:isolation]
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
        if sqlserver? && starting_isolation_level
          connection.set_transaction_isolation_level(starting_isolation_level)
        end
      end

    end

    RealTransaction.send :include, SQLServerRealTransaction

  end
end
