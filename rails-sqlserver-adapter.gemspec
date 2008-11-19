Gem::Specification.new do |s|
  s.name = "sqlserver-05-adapter"
  s.version = "2.2.1"
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ['Ken Collins','Murray Steele','Shawn Balestracci','Tom Ward']
  s.date = "2008-09-27"
  s.email = "ken@metaskills.net"
  s.files = ["lib/active_record/connection_adapters/sqlserver_adapter.rb"]
  s.homepage = %q{http://vegantech.lighthouseapp.com/projects/17542-activerecord-sqlserver-adapter}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{activerecord}
  s.rubygems_version = %q{1.1.1}
  s.summary = "SQL Server 2000 & 2005 Adapter For Rails"
  s.add_dependency(%q<activerecord>, [">= 2.2.1"])
end
