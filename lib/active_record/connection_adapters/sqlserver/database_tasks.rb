module ActiveRecord
  module Tasks
    class SQLServerDatabaseTasks
      DEFAULT_ENCODING = ENV['CHARSET'] || 'utf8'

      delegate :connection, :establish_connection, :clear_active_connections!,
        to: ActiveRecord::Base

      def initialize(configuration)
        @configuration = configuration
      end

      def create(master_established = false)
        establish_master_connection unless master_established
        connection.create_database configuration['database']
        establish_connection configuration
      rescue ActiveRecord::StatementInvalid => error
        if /Database .* already exists/ === error.message
          raise DatabaseAlreadyExists
        else
          raise
        end
      end

      def drop
        establish_master_connection
        connection.drop_database configuration['database']
      end

      def purge
        clear_active_connections!
        drop
        create true
      end

      def structure_dump(filename)
        #Will need to determine a tool that allows this
        raise 'Cannot dump structure with SQLServer currently'
      end

      def structure_load(filename)
        #Will need to determine a tool that allows this
        raise 'Cannot load structure with SQLServer currently'
      end

      private

        def configuration
          @configuration
        end

        def establish_master_connection
          establish_connection configuration.merge(
            'database'           => 'master'
          )
        end

    end
  end
end
