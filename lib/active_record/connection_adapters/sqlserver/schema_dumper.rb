# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class SchemaDumper < ConnectionAdapters::SchemaDumper
        SQLSEVER_NO_LIMIT_TYPES = [
          "text",
          "ntext",
          "varchar(max)",
          "nvarchar(max)",
          "varbinary(max)"
        ].freeze

        private

        def explicit_primary_key_default?(column)
          column.type == :integer && !column.is_identity?
        end

        def schema_limit(column)
          return if SQLSEVER_NO_LIMIT_TYPES.include?(column.sql_type)

          super
        end

        def schema_collation(column)
          return unless column.collation

          # use inspect to ensure collation is dumped as string. Without this it's dumped as
          # a constant ('collation: SQL_Latin1_General_CP1_CI_AS')
          collation = column.collation.inspect
          # use inspect to ensure string comparison
          default_collation = @connection.collation.inspect

          collation if collation != default_collation
        end

        def default_primary_key?(column)
          super && column.is_identity?
        end
      end
    end
  end
end
