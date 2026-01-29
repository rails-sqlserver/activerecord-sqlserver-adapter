# -*- encoding: utf-8 -*-
# stub: tiny_tds 3.4.0 x86_64-linux-gnu lib

Gem::Specification.new do |s|
  s.name = "tiny_tds".freeze
  s.version = "3.4.0".freeze
  s.platform = "x86_64-linux-gnu".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 3.3.22".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ken Collins".freeze, "Erik Bryn".freeze, "Will Bond".freeze]
  s.date = "1980-01-02"
  s.description = "TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library. Developed for the ActiveRecord SQL Server adapter.".freeze
  s.email = ["ken@metaskills.net".freeze, "will@wbond.net".freeze]
  s.executables = ["defncopy-ttds".freeze, "tsql-ttds".freeze]
  s.files = ["bin/defncopy-ttds".freeze, "bin/tsql-ttds".freeze]
  s.homepage = "http://github.com/rails-sqlserver/tiny_tds".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 3.0".freeze, "< 4.1.dev".freeze])
  s.rubygems_version = "3.5.3".freeze
  s.summary = "TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 2.0.0".freeze])
  s.add_development_dependency(%q<mini_portile2>.freeze, ["~> 2.8.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.2.0".freeze])
  s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.2".freeze])
  s.add_development_dependency(%q<rake-compiler-dock>.freeze, ["~> 1.11.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.25".freeze])
  s.add_development_dependency(%q<minitest-reporters>.freeze, ["~> 1.6.1".freeze])
  s.add_development_dependency(%q<connection_pool>.freeze, ["~> 2.2.0".freeze])
  s.add_development_dependency(%q<toxiproxy>.freeze, ["~> 2.0.0".freeze])
  s.add_development_dependency(%q<standard>.freeze, ["~> 1.31.0".freeze])
  s.add_development_dependency(%q<ostruct>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<benchmark>.freeze, [">= 0".freeze])
end
