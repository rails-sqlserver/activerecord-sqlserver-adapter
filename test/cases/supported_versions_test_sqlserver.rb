require 'cases/sqlserver_helper'

class SupportedVersionsTestSqlserver < ActiveRecord::TestCase

  class TestSupportedVersions
    include ActiveRecord::ConnectionAdapters::Sqlserver::SupportedVersions
  end

  should 'allow SQL Server 2005, 2008, and 2012' do
    assert_true TestSupportedVersions.new.supports_version?('9')  # SQL Server 2005
    assert_true TestSupportedVersions.new.supports_version?('10') # SQL Server 2008
    assert_true TestSupportedVersions.new.supports_version?('11') # SQL Server 2012
  end

  should 'not support an invalid version' do
    assert_false TestSupportedVersions.new.supports_version?('Foo')
  end

  should 'raise an error if the version is unsupported' do
    assert_raise(NotImplementedError) {
      TestSupportedVersions.new.ensure_supported_version('8')
    }
  end
end
