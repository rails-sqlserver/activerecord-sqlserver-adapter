require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"
  gem "tiny_tds"
  gem "activerecord", "x.x.x"
  gem "activerecord-sqlserver-adapter", "x.x.x"
end

require "active_record"
require "minitest/autorun"
require "logger"

ActiveRecord::Base.establish_connection(
    adapter:  "sqlserver",
    timeout:  5000,
    pool:     100,
    encoding: "utf8",
    database: "test_database",
    username: "SA",
    password: "StrongPassword!",
    host:     "localhost",
    port:     1433,
    )
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  drop_table :bug_tests rescue nil

  create_table :bug_tests, force: true do |t|
    t.bigint :external_id
  end
end

class BugTest < ActiveRecord::Base
end

class TestBugTest < Minitest::Test
  def setup
    @bug_test = BugTest.create!(external_id: 2_032_070_100_001)
  end

  def test_count
    assert_equal 1, BugTest.count
  end
end