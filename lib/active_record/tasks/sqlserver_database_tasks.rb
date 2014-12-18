module ActiveRecord
  module Tasks # :nodoc:
    class SQLServerDatabaseTasks # :nodoc:
      delegate :connection, :establish_connection, to: ActiveRecord::Base

      def initialize(configuration)
        @configuration = configuration
      end

      def create
        establish_connection configuration
        connection.create_database configuration['database']
      end

      def drop
        establish_connection configuration
        connection.drop_database configuration['database']
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

      ActiveRecord::Tasks::DatabaseTasks.register_task(/sqlserver/, ActiveRecord::Tasks::SQLServerDatabaseTasks)
    end
  end
end
