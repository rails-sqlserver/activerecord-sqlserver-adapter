module ActiveRecord
  module ConnectionAdapters
    class SQLServerColumn < Column

      def initialize(name, default, cast_type, sql_type = nil, null = true, sqlserver_options = {})
        super(name, default, cast_type, sql_type, null)
        @sqlserver_options = sqlserver_options.symbolize_keys
        @default_function = @sqlserver_options[:default_function]
      end

      def sql_type_for_statement
        if is_integer? || is_real?
          sql_type.sub(/\((\d+)?\)/, '')
        else
          sql_type
        end
      end

      def table_name
        @sqlserver_options[:table_name]
      end

      def is_identity?
        @sqlserver_options[:is_identity]
      end

      def is_primary?
        @sqlserver_options[:is_primary]
      end

      def is_utf8?
        @sql_type =~ /nvarchar|ntext|nchar/i
      end

      def is_integer?
        @sql_type =~ /int/i
      end

      def is_real?
        @sql_type =~ /real/i
      end

      def collation
        @sqlserver_options[:collation]
      end

      def case_sensitive?
        collation && !collation.match(/_CI/)
      end

    end
  end
end
