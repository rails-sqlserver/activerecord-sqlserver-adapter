# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      class Column < ConnectionAdapters::Column
        delegate :is_identity, :is_primary, :table_name, :ordinal_position, to: :sql_type_metadata

        def initialize(*, is_identity: nil, is_primary: nil, table_name: nil, ordinal_position: nil, **)
          super
          @is_identity = is_identity
          @is_primary = is_primary
          @table_name = table_name
          @ordinal_position = ordinal_position
        end

        def is_identity?
          is_identity
        end
        alias_method :auto_incremented_by_db?, :is_identity?

        def is_primary?
          is_primary
        end

        def is_utf8?
          sql_type =~ /nvarchar|ntext|nchar/i
        end

        def case_sensitive?
          collation && collation.match(/_CS/)
        end

        def init_with(coder)
          @is_identity = coder["is_identity"]
          @is_primary = coder["is_primary"]
          @table_name = coder["table_name"]
          @ordinal_position = coder["ordinal_position"]
          super
        end

        def encode_with(coder)
          coder["is_identity"] = @is_identity
          coder["is_primary"] = @is_primary
          coder["table_name"] = @table_name
          coder["ordinal_position"] = @ordinal_position
          super
        end

        def ==(other)
          other.is_a?(Column) &&
            super &&
            is_identity? == other.is_identity? &&
            is_primary? == other.is_primary? &&
            table_name == other.table_name &&
            ordinal_position == other.ordinal_position
        end
        alias :eql? :==

        def hash
          Column.hash ^
            super.hash ^
            is_identity?.hash ^
            is_primary?.hash ^
            table_name.hash ^
            ordinal_position.hash
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

      SQLServerColumn = SQLServer::Column
    end
  end
end
