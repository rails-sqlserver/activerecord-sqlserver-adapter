# frozen_string_literal: true

version = File.read(File.expand_path("VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = "activerecord-sqlserver-adapter"
  spec.platform      = Gem::Platform::RUBY
  spec.version       = version

  spec.required_ruby_version = ">= 2.5.0"

  spec.license       = "MIT"
  spec.authors       = ["Ken Collins", "Anna Carey", "Will Bond", "Murray Steele", "Shawn Balestracci", "Joe Rafaniello", "Tom Ward"]
  spec.email         = ["ken@metaskills.net", "will@wbond.net"]
  spec.homepage      = "http://github.com/rails-sqlserver/activerecord-sqlserver-adapter"
  spec.summary       = "ActiveRecord SQL Server Adapter."
  spec.description   = "ActiveRecord SQL Server Adapter. SQL Server 2012 and upward."

  spec.metadata      = {
    "bug_tracker_uri" => "https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/issues",
    "changelog_uri" => "https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/blob/v#{version}/CHANGELOG.md",
    "source_code_uri" => "https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/tree/v#{version}",
  }

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 6.0.0"
  spec.add_dependency "tiny_tds"
end
