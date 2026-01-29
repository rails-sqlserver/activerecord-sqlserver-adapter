$LOAD_PATH.push File.expand_path("../lib", __FILE__)
version = File.read(File.expand_path("VERSION", __dir__)).strip

Gem::Specification.new do |s|
  s.name = "tiny_tds"
  s.version = version
  s.platform = Gem::Platform::RUBY
  s.authors = ["Ken Collins", "Erik Bryn", "Will Bond"]
  s.email = ["ken@metaskills.net", "will@wbond.net"]
  s.homepage = "http://github.com/rails-sqlserver/tiny_tds"
  s.summary = "TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library."
  s.description = "TinyTDS - A modern, simple and fast FreeTDS library for Ruby using DB-Library. Developed for the ActiveRecord SQL Server adapter."
  s.files = `git ls-files`.split("\n") + Dir.glob("exe/*")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.rdoc_options = ["--charset=UTF-8"]
  s.extensions = ["ext/tiny_tds/extconf.rb"]
  s.license = "MIT"
  s.required_ruby_version = ">= 2.7.0"
  s.metadata["msys2_mingw_dependencies"] = "freetds"
  s.add_dependency "bigdecimal", ">= 2.0.0"
  s.add_development_dependency "mini_portile2", "~> 2.8.0"
  s.add_development_dependency "rake", "~> 13.2.0"
  s.add_development_dependency "rake-compiler", "~> 1.2"
  s.add_development_dependency "rake-compiler-dock", "~> 1.11.0"
  s.add_development_dependency "minitest", "~> 5.25"
  s.add_development_dependency "minitest-reporters", "~> 1.6.1"
  s.add_development_dependency "connection_pool", "~> 2.2.0"
  s.add_development_dependency "toxiproxy", "~> 2.0.0"
  s.add_development_dependency "standard", "~> 1.31.0"
  # ostruct can be dropped when updating to Rubocop 1.65+
  s.add_development_dependency "ostruct"
  s.add_development_dependency "benchmark"
end
