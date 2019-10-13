module ActiveRecord
  module ConnectionAdapters
    class SQLServerColumn < Column

      def initialize(name, default, sql_type_metadata = nil, null = true, table_name = nil, default_function = nil, collation = nil, comment = nil, **)
        @sqlserver_options = {}
        @name = name.freeze
        @sql_type_metadata = sql_type_metadata
        @null = null
        @default = default
        @default_function = default_function
        @collation = collation
        @comment = comment
      end

      def is_identity?
        @sqlserver_options[:is_identity]
      end

      def is_primary?
        @sqlserver_options[:is_primary]
      end

      def is_utf8?
        sql_type =~ /nvarchar|ntext|nchar/i
      end

      def case_sensitive?
        collation && collation.match(/_CS/)
      end

    end
  end
end
