module ActiveRecord
  module Tasks # :nodoc:
    class SQLServerDatabaseTasks # :nodoc:
      delegate :connection, :establish_connection, to: ActiveRecord::Base

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

      def drop(master_established = false)
        establish_master_connection unless master_established
        connection.drop_database configuration['database']
        establish_connection configuration
      end

      def purge
        establish_connection configuration
        connection.recreate_database
      end

    private

      def configuration
        @configuration
      end

      def creation_options
        Hash.new.tap do |options|
          options[:charset]     = configuration['encoding']   if configuration.include? 'encoding'
          options[:collation]   = configuration['collation']  if configuration.include? 'collation'

          # Set default charset only when collation isn't set.
          options[:charset]   ||= DEFAULT_CHARSET unless options[:collation]

          # Set default collation only when charset is also default.
          options[:collation] ||= DEFAULT_COLLATION if options[:charset] == DEFAULT_CHARSET
        end
      end

      def establish_master_connection
        establish_connection configuration.merge(
                               'database' => 'master'
                             )
      end

      ActiveRecord::Tasks::DatabaseTasks.register_task(/sqlserver/, ActiveRecord::Tasks::SQLServerDatabaseTasks)
    end
  end
end
