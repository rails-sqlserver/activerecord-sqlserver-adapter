# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module SQLServer
      module DatabaseLimits
        def table_alias_length
          128
        end

        def table_name_length
          128
        end

        def index_name_length
          128
        end

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
