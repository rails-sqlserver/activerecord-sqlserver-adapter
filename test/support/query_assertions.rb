module ARTest
  module SQLServer
    module QueryAssertions
      def assert_queries_count(count = nil, include_schema: false, &block)
        ActiveRecord::Base.lease_connection.materialize_transactions

        counter = ActiveRecord::Assertions::QueryAssertions::SQLCounter.new
        ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
          result = _assert_nothing_raised_or_warn("assert_queries_count", &block)
          queries = include_schema ? counter.log_all : counter.log

          # Start of monkey-patch
          queries = include_release_savepoint_placeholder_queries(queries)
          # End of monkey-patch

          if count
            assert_equal count, queries.size, "#{queries.size} instead of #{count} queries were executed. Queries: #{queries.join("\n\n")}"
          else
            assert_operator queries.size, :>=, 1, "1 or more queries expected, but none were executed.#{queries.empty? ? '' : "\nQueries:\n#{queries.join("\n")}"}"
          end
          result
        end
      end

      private

      # Rails tests expect a save-point to be created and released. SQL Server does not release
      # save-points and so the number of queries will be off. This monkey patch adds a placeholder queries
      # to replace the missing save-point releases.
      def include_release_savepoint_placeholder_queries(queries)
        grouped_queries = [[]]

        queries.each do |query|
          if query =~ /SAVE TRANSACTION \S+/
            grouped_queries << [query]
          else
            grouped_queries.last << query
          end
        end

        grouped_queries.each do |group|
          group.append "/* release savepoint placeholder for testing */" if group.first =~ /SAVE TRANSACTION \S+/
        end

        grouped_queries.flatten
      end
    end
  end
end
