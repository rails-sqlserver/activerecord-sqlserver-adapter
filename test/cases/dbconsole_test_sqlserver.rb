# frozen_string_literal: true

require "cases/helper_sqlserver"

class DbConsole < ActiveRecord::TestCase
  subject { ActiveRecord::ConnectionAdapters::SQLServerAdapter }

  it "uses sqlcmd to connect to database" do
    assert_called_with(subject, :find_cmd_and_exec, ["sqlcmd", "-d", "db", "-U", "user", "-P", "secret", "-C", "-S", "tcp:localhost,1433"]) do
      config = make_db_config(adapter: "sqlserver", database: "db", username: "user", password: "secret", host: "localhost", port: 1433, trust_server_certificate: true)

      subject.dbconsole(config)
    end
  end

  private

  def make_db_config(config)
    ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "primary", config)
  end
end
