module ARTest
  module SQLServer

    extend self

    attr_accessor :sql_counter_listenter

    def ignored_sql
      [ /SELECT SCOPE_IDENTITY/,
        /INFORMATION_SCHEMA\.(TABLES|VIEWS|COLUMNS)/,
        /SELECT @@version/,
        /SELECT @@TRANCOUNT/,
        /(BEGIN|COMMIT|ROLLBACK|SAVE) TRANSACTION/,
        /SELECT CAST\(.* AS .*\) AS value/ ]
    end

    def sql_counter_listenters
      ActiveSupport::Notifications.notifier.listeners_for('sql.active_record').select do |listener|
        listener.inspect =~ /ActiveRecord::SQLCounter/
      end
    end

    def sql_counter_listenters_unsubscribe
      sql_counter_listenters.each { |listener| ActiveSupport::Notifications.unsubscribe(listener) }
    end

  end
end

ActiveRecord::SQLCounter.ignored_sql.concat ARTest::SQLServer.ignored_sql
ARTest::SQLServer.sql_counter_listenters_unsubscribe
ARTest::SQLServer.sql_counter_listenter = ActiveSupport::Notifications.subscribe 'sql.active_record', ActiveRecord::SQLCounter.new
