# -*- ruby -*-

# Specify your gem's runtime dependencies in pg.gemspec
gemspec

source "https://rubygems.org/"

group :development, :test do
  gem "bundler", ">= 1.16", "< 3.0"
  gem "rake-compiler", "~> 1.0"
  gem "rake-compiler-dock", "~> 1.0"
  gem "rdoc", "~> 6.4"
  gem "rspec", "~> 3.5"
  gem "ostruct", "~> 0.5" # for Rakefile.cross
  # "bigdecimal" is a gem on ruby-3.4+ and it's optional for ruby-pg.
  # Specs should succeed without it, but 4 examples are then excluded.
  # With bigdecimal commented out here, corresponding tests are omitted on ruby-3.4+ but are executed on ruby < 3.4.
  # That way we can check both situations in CI.
  # gem "bigdecimal", "~> 3.0"
end
