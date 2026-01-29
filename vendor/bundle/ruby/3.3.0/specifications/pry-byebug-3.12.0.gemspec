# -*- encoding: utf-8 -*-
# stub: pry-byebug 3.12.0 ruby lib

Gem::Specification.new do |s|
  s.name = "pry-byebug".freeze
  s.version = "3.12.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/deivid-rodriguez/pry-byebug/issues", "changelog_uri" => "https://github.com/deivid-rodriguez/pry-byebug/blob/HEAD/CHANGELOG.md", "funding_uri" => "https://liberapay.com/pry-byebug", "source_code_uri" => "https://github.com/deivid-rodriguez/pry-byebug" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Rodr\u00EDguez".freeze, "Gopal Patel".freeze]
  s.date = "1980-01-02"
  s.description = "Combine 'pry' with 'byebug'. Adds 'step', 'next', 'finish',\n    'continue' and 'break' commands to control execution.".freeze
  s.email = "deivid.rodriguez@gmail.com".freeze
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "README.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "README.md".freeze]
  s.homepage = "https://github.com/deivid-rodriguez/pry-byebug".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Fast debugging with Pry.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<byebug>.freeze, ["~> 13.0".freeze])
  s.add_runtime_dependency(%q<pry>.freeze, [">= 0.13".freeze, "< 0.17".freeze])
end
