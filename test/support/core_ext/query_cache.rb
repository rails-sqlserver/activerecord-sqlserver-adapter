# frozen_string_literal: true

require "active_record/connection_adapters/sqlserver_adapter"

module SqlIgnoredCache
  extend ActiveSupport::Concern

  IGNORED_SQL = [
    /INFORMATION_SCHEMA\.(TABLES|VIEWS|COLUMNS|KEY_COLUMN_USAGE)/im,
    /sys.columns/i,
    /SELECT @@version/,
    /SELECT @@TRANCOUNT/,
    /(BEGIN|COMMIT|ROLLBACK|SAVE) TRANSACTION/,
    /SELECT CAST\(.* AS .*\) AS value/,
    /SELECT DATABASEPROPERTYEX/im
  ]

  # We don't want to coerce every ActiveRecord test that relies on `query_cache`
  # just because we do more queries than the other adapters.
  #
  # Removing internal queries from the cache will make AR tests pass without
  # compromising cache outside tests.
  def cache_sql(sql, name, binds)
    result = super
    @query_cache.delete_if { |k, v| k =~ Regexp.union(IGNORED_SQL) }
    result
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::SQLServerAdapter.prepend(SqlIgnoredCache)
end
