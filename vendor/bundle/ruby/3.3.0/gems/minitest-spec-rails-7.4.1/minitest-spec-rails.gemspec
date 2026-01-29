$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'minitest-spec-rails/version'

Gem::Specification.new do |gem|
  gem.name        = 'minitest-spec-rails'
  gem.version     = MiniTestSpecRails::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ['Ken Collins']
  gem.email       = ['ken@metaskills.net']
  gem.homepage    = 'http://github.com/metaskills/minitest-spec-rails'
  gem.summary     = 'Make Rails Use Minitest::Spec!'
  gem.description = 'The minitest-spec-rails gem makes it easy to use the \
                     Minitest::Spec DSL within your existing Rails test suite.'
  gem.license     = 'MIT'
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.require_paths = ['lib']
  gem.add_runtime_dependency     'minitest', '>= 5.0'
  gem.add_runtime_dependency     'railties', '>= 4.1'
  gem.add_development_dependency 'appraisal'
  gem.add_development_dependency 'minitest-focus'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'sqlite3'
end
