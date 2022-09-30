# frozen_string_literal: true

class DbConsole < ActiveRecord::TestCase
  subject { ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter }

  it "uses sqlplus to connect to database" do
    subject.expects(:find_cmd_and_exec).with("sqlcmd", "-d", "db", "-U", "user", "-P", "secret", "-S", "tcp:localhost,1433")

    config = make_db_config(adapter: "sqlserver", database: "db", username: "user", password: "secret", host: "localhost", port: 1433)

    subject.dbconsole(config)
  end

  private

  def make_db_config(config)
    ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "primary", config)
  end
end
