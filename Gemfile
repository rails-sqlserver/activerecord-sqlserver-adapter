
source 'https://rubygems.org'

if ENV['RAILS_SOURCE']
  gemspec :path => ENV['RAILS_SOURCE']
else
  gem 'rails', :git => "git://github.com/rails/rails.git", :tag => "v3.2.22"
end

if ENV['AREL']
  gem 'arel', :path => ENV['AREL']
end

group :tinytds do
  if ENV['TINYTDS_SOURCE']
    gem 'tiny_tds', :path => ENV['TINYTDS_SOURCE']
  else
    gem 'tiny_tds', '~> 0.6.0'
  end
end

group :odbc do
  gem 'ruby-odbc'
end

group :development do
  gem 'bcrypt-ruby', '~> 3.0.0'
  gem 'bench_press'
  gem 'mocha'
  gem 'minitest-spec-rails', '~> 4.7.9'
  gem 'nokogiri'
  gem 'rake', '~> 0.9.2'
  gem 'ruby-prof'
end

