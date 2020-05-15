# frozen_string_literal: true

module ARTest
  module SQLServer
    module SqlCounterSqlserver
      # Only return the log vs. log_all
      def capture_sql_ss
        ActiveRecord::SQLCounter.clear_log
        yield
        ActiveRecord::SQLCounter.log.dup
      end
    end

    ignored_sql = [
      /INFORMATION_SCHEMA\.(TABLES|VIEWS|COLUMNS|KEY_COLUMN_USAGE)/im,
      /sys.columns/i,
      /SELECT @@version/,
      /SELECT @@TRANCOUNT/,
      /(BEGIN|COMMIT|ROLLBACK|SAVE) TRANSACTION/,
      /SELECT CAST\(.* AS .*\) AS value/,
      /SELECT DATABASEPROPERTYEX/im
    ]

    sqlcounter = ObjectSpace.each_object(ActiveRecord::SQLCounter).to_a.first
    sqlcounter.instance_variable_set :@ignore, Regexp.union(ignored_sql.push(sqlcounter.ignore))
  end
end
