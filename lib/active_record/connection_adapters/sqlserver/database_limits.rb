# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module DatabaseLimits
        def table_alias_length
          128
        end

        def column_name_length
          128
        end
        deprecate :column_name_length

        def table_name_length
          128
        end
        deprecate :table_name_length

        def index_name_length
          128
        end

        def columns_per_table
          1024
        end
        deprecate :columns_per_table

        def indexes_per_table
          999
        end
        deprecate :indexes_per_table

        def columns_per_multicolumn_index
          16
        end
        deprecate :columns_per_multicolumn_index

        def in_clause_length
          10_000
        end

        def sql_query_length
          65_536 * 4_096
        end
        deprecate :sql_query_length

        def joins_per_query
          256
        end
        deprecate :joins_per_query

        private

        # The max number of binds is 2100, but because sp_executesql takes
        # the first 2 params as the query string and the list of types,
        # we have only 2098 spaces left
        def bind_params_length
          2_098
        end

        def insert_rows_length
          1_000
        end
      end
    end
  end
end
