require 'cases/test_case.rb'

# TODO: I'm struggling to figure out how to unsubscribe from only one 'sql.active_record'
# This is a temporary hack until we can just get the sqlserver_ignored regex in rails
ActiveSupport::Notifications.notifier.listeners_for('sql.active_record').each do |listener|
   if listener.inspect =~ /ActiveRecord::SQLCounter/
    ActiveSupport::Notifications.unsubscribe(listener)
  end
end

module ActiveRecord
  class SQLCounter
     sqlserver_ignored =  [%r|SELECT SCOPE_IDENTITY|, %r{INFORMATION_SCHEMA\.(TABLES|VIEWS|COLUMNS)},%r|SELECT @@version|, %r|SELECT @@TRANCOUNT|, %r{(BEGIN|COMMIT|ROLLBACK|SAVE) TRANSACTION}]
     ignored_sql.concat sqlserver_ignored
  end
  ActiveSupport::Notifications.subscribe('sql.active_record', SQLCounter.new)
end