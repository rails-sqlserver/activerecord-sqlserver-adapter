module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module SchemaDumper

        SQLSEVER_NO_LIMIT_TYPES = [
          'text',
          'ntext',
          'varchar(max)',
          'nvarchar(max)',
          'varbinary(max)'
        ].freeze

        private

        def explicit_primary_key_default?(column)
          column.is_primary? && !column.is_identity?
        end

        def schema_limit(column)
          return if SQLSEVER_NO_LIMIT_TYPES.include?(column.sql_type)
          super
        end

        def schema_collation(column)
          return unless column.collation
          column.collation if column.collation != collation
        end

        def default_primary_key?(column)
          super && column.is_primary? && column.is_identity?
        end
      end
    end
  end

  class SchemaDumper
    private

    def remove_prefix_and_suffix(table)
      table = remove_schema(table)
      table.gsub(/^(#{@options[:table_name_prefix]})(.+)(#{@options[:table_name_suffix]})$/,  "\\2")
    end

    def remove_schema(table_with_schema)
      identifier = ActiveRecord::ConnectionAdapters::SQLServer::Utils.extract_identifiers(table_with_schema)
      identifier.object
    end
  end
end
