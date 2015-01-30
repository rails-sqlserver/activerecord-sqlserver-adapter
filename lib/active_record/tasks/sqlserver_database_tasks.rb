require 'shellwords'

module ActiveRecord
  module Tasks # :nodoc:
    class SQLServerDatabaseTasks # :nodoc:
      DEFAULT_COLLATION = 'SQL_Latin1_General_CP1_CI_AS'

      delegate :connection, :establish_connection, :clear_active_connections!,
        to: ActiveRecord::Base

      def initialize(configuration)
        @configuration = configuration
      end

      def create(master_established = false)
        establish_master_connection unless master_established
        connection.create_database configuration['database'], default_collation
        establish_connection configuration
      rescue ActiveRecord::StatementInvalid => error
        if /[Dd]atabase .* already exists/ === error.message
          raise DatabaseAlreadyExists
        else
          raise
        end
      end

      def drop
        establish_master_connection
        connection.drop_database configuration['database']
      end

      def charset
        connection.charset
      end

      def collation
        connection.collation
      end

      def purge
        clear_active_connections!
        drop
        create true
      end

      def structure_dump(filename)
        command = ([
            "defncopy",
            "-S #{Shellwords.escape(configuration['host'])}",
            "-D #{Shellwords.escape(configuration['database'])}",
            "-U #{Shellwords.escape(configuration['username'])}",
            "-P #{Shellwords.escape(configuration['password'])}",
            "-o #{Shellwords.escape(filename)}",
          ]
          .concat(connection.tables.map{|t| Shellwords.escape(t)})
          .concat(connection.views.map{|v| Shellwords.escape(v)})
        ).join(' ')
        raise 'Error dumping database' unless Kernel.system(command)
        dump = File.read(filename).gsub(/^USE .*$\nGO\n/, '') # Strip db USE statements
        dump.gsub!(/nvarchar\(-1\)/, 'nvarchar(max)')         # Fix nvarchar(-1) column defs
        dump.gsub!(/text\(\d+\)/, 'text')                     # Fix text(16) column defs
        File.open(filename, "w") { |file| file.puts dump }
        warn "NOTE: FreeTDS defncopy is used for dumping, which does yet not properly dump foreign key constraints."
      end

      def structure_load(filename)
        command = ([
            "tsql",
            "-S #{Shellwords.escape(configuration['host'])}",
            "-D #{Shellwords.escape(configuration['database'])}",
            "-U #{Shellwords.escape(configuration['username'])}",
            "-P #{Shellwords.escape(configuration['password'])}",
            "< #{Shellwords.escape(filename)}",
          ]).join(' ')
        raise 'Error loading database' unless Kernel.system(command)
      end

      private

      def default_collation
        configuration['collation'] || DEFAULT_COLLATION
      end

      def configuration
        @configuration
      end

      def establish_master_connection
        establish_connection configuration.merge('database' => 'master')
      end
    end
    DatabaseTasks.register_task(/sqlserver/, ActiveRecord::Tasks::SQLServerDatabaseTasks)
  end
end
