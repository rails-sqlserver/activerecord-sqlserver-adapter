module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module SchemaDumper

        private

        def schema_collation(column)
          return unless column.collation
          column.collation if column.collation != collation
        end

      end
    end
  end
end
