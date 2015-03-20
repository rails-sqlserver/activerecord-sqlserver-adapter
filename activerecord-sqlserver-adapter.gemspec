# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_record/connection_adapters/sqlserver/version"

Gem::Specification.new do |spec|
  spec.name          = 'activerecord-sqlserver-adapter'
  spec.version       = ActiveRecord::ConnectionAdapters::SQLServer::Version::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Ken Collins', 'Anna Carey', 'Will Bond', 'Murray Steele', 'Shawn Balestracci', 'Joe Rafaniello', 'Tom Ward']
  spec.email         = ['ken@metaskills.net', 'will@wbond.net']
  spec.homepage      = 'http://github.com/rails-sqlserver/activerecord-sqlserver-adapter'
  spec.summary       = 'ActiveRecord SQL Server Adapter.'
  spec.description   = spec.summary
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.add_dependency 'activerecord', '~> 4.2.1'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-minitest'
  spec.add_development_dependency 'minitest', '< 5.3.4' # PENDING: [Rails5.x] Remove test order constraint.
  spec.add_development_dependency 'minitest-focus'
  spec.add_development_dependency 'minitest-spec-rails'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'nokogiri'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
end
