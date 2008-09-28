Gem::Specification.new do |s|
  s.name = %q{activerecord-sqlserver-adapter}
  s.version = "1.0.1"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Shawn Balestracci"]
  s.date = %q{2008-09-27}
  s.email = %q{shawn@vegantech.com}
  s.files = ["lib/active_record/connection_adapters/sqlserver_adapter.rb"]
  s.homepage = %q{http://vegantech.lighthouseapp.com/projects/17542-activerecord-sqlserver-adapter}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{activerecord}
  s.rubygems_version = %q{1.1.1}
  s.summary = %q{SQL Server adapter for Active Record}

  s.add_dependency(%q<activerecord>, [">= 1.15.5.7843"])
end
