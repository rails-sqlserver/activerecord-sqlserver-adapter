# -*- encoding: utf-8 -*-
# stub: minitest-spec-rails 7.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "minitest-spec-rails".freeze
  s.version = "7.4.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ken Collins".freeze]
  s.date = "2024-11-17"
  s.description = "The minitest-spec-rails gem makes it easy to use the \\\n                     Minitest::Spec DSL within your existing Rails test suite.".freeze
  s.email = ["ken@metaskills.net".freeze]
  s.homepage = "http://github.com/metaskills/minitest-spec-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Make Rails Use Minitest::Spec!".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<minitest>.freeze, [">= 5.0".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 4.1".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-focus>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0".freeze])
end
