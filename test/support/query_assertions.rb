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
          # Rails tests expect a save-point to be released at the end of the test. SQL Server does not release
          # save-points and so the number of queries will be off by one. This monkey patch adds a placeholder query
          # to the end of the queries array to account for the missing save-point release.
          if queries.any? { |query| query =~ /SAVE TRANSACTION \S+/ }
            queries.append "/* release savepoint placeholder for testing */"
          end
          # End of monkey-patch

          if count
            assert_equal count, queries.size, "#{queries.size} instead of #{count} queries were executed. Queries: #{queries.join("\n\n")}"
          else
            assert_operator queries.size, :>=, 1, "1 or more queries expected, but none were executed.#{queries.empty? ? '' : "\nQueries:\n#{queries.join("\n")}"}"
          end
          result
        end
      end
    end
  end
end
