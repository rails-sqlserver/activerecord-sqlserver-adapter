require "cases/helper"

module ActiveRecord
  module ConnectionAdapters
    class ConnectionSpecification

      class ResolverTest < ActiveRecord::TestCase

        include SqlserverCoercedTest

        COERCED_TESTS = [
          :test_url_host_no_db,
          :test_url_host_db,
          :test_url_port
        ]

        def test_coerced_test_url_host_no_db
          spec = resolve 'sqlserver://foo?encoding=utf8'
          assert_equal({
            "adapter" => "sqlserver",
            "host" => "foo",
            "encoding" => "utf8" }, spec)
        end

        def test_coerced_test_url_host_db
          spec = resolve 'sqlserver://foo/bar?encoding=utf8'
          assert_equal({
            "adapter" => "sqlserver",
            "database" => "bar",
            "host" => "foo",
            "encoding" => "utf8" }, spec)
        end

        def test_coerced_test_url_port
          spec = resolve 'sqlserver://foo:123?encoding=utf8'
          assert_equal({
            "adapter" => "sqlserver",
            "port" => 123,
            "host" => "foo",
            "encoding" => "utf8" }, spec)
        end
      end

    end
  end
end
