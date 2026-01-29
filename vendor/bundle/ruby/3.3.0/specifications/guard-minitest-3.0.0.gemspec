# -*- encoding: utf-8 -*-
# stub: guard-minitest 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "guard-minitest".freeze
  s.version = "3.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/guard/guard-minitest/issues", "changelog_uri" => "https://github.com/guard/guard-minitest/releases", "source_code_uri" => "https://github.com/guard/guard-minitest" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yann Lugrin".freeze, "R\u00E9my Coutable".freeze]
  s.date = "1980-01-02"
  s.description = "Guard::Minitest automatically run your tests with Minitest framework (much like autotest)".freeze
  s.email = ["remy@rymai.me".freeze]
  s.homepage = "https://github.com/guard/guard-minitest".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Guard plugin for the Minitest framework".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<guard-compat>.freeze, ["~> 1.2".freeze])
  s.add_runtime_dependency(%q<minitest>.freeze, [">= 5.0.4".freeze, "< 7.0".freeze])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<guard-rubocop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.1".freeze])
end
