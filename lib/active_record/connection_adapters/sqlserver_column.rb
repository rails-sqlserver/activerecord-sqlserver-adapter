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
    end
  end
end
