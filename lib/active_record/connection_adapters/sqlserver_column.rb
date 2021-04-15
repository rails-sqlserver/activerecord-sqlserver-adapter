# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    class SQLServerColumn < Column
      def initialize(name, default, sql_type_metadata = nil, null = true, default_function = nil, collation: nil, comment: nil, **sqlserver_options)
        @sqlserver_options = sqlserver_options
        super
      end

      def is_identity?
        @sqlserver_options[:is_identity]
      end

      def is_primary?
        @sqlserver_options[:is_primary]
      end

      def table_name
        @sqlserver_options[:table_name]
      end

      def is_utf8?
        sql_type =~ /nvarchar|ntext|nchar/i
      end

      def case_sensitive?
        collation && collation.match(/_CS/)
      end

      private

      # In the Rails version of this method there is an assumption that the `default` value will always be a
      # `String` class, which must be true for the MySQL/PostgreSQL/SQLite adapters. However, in the SQL Server
      # adapter the `default` value can also be Boolean/Date/Time/etc. Changed the implementation of this method
      # to handle non-String `default` objects.
      def deduplicated
        @name = -name
        @sql_type_metadata = sql_type_metadata.deduplicate if sql_type_metadata
        @default = (default.is_a?(String) ? -default : default.dup.freeze) if default
        @default_function = -default_function if default_function
        @collation = -collation if collation
        @comment = -comment if comment

        freeze
      end
    end
  end
end
