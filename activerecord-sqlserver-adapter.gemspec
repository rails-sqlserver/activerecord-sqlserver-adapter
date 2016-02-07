# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_record/connection_adapters/sqlserver/version"

Gem::Specification.new do |spec|
  spec.name          = 'activerecord-sqlserver-adapter'
  spec.version       = ActiveRecord::ConnectionAdapters::SQLServer::Version::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.license       = 'MIT'
  spec.authors       = ['Ken Collins', 'Anna Carey', 'Will Bond', 'Murray Steele', 'Shawn Balestracci', 'Joe Rafaniello', 'Tom Ward']
  spec.email         = ['ken@metaskills.net', 'will@wbond.net']
  spec.homepage      = 'http://github.com/rails-sqlserver/activerecord-sqlserver-adapter'
  spec.summary       = 'ActiveRecord SQL Server Adapter.'
  spec.description   = 'ActiveRecord SQL Server Adapter. SQL Server 2012 and upward.'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.add_dependency 'activerecord', '~> 4.2.1'
end
