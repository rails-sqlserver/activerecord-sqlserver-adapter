
source :rubygems

if ENV['RAILS_SOURCE']
  gemspec :path => ENV['RAILS_SOURCE']
else
  spec = eval(File.read('activerecord-sqlserver-adapter.gemspec'))
  ar_version = spec.dependencies.detect{ |d|d.name == 'activerecord' }.requirement.requirements.first.last.version
  gem 'rails', :git => "git://github.com/rails/rails.git", :tag => "v#{ar_version}"
  gem 'bcrypt-ruby', '~> 3.0.0'
end

if ENV['AREL']
  gem 'arel', :path => ENV['AREL']
end

group :tinytds do
  if ENV['TINYTDS_SOURCE']
    gem 'tiny_tds', :path => ENV['TINYTDS_SOURCE']
  else
    gem 'tiny_tds', '>= 0.4.5'
  end
end

group :odbc do
  gem 'ruby-odbc'
end

group :development do
  gem 'rake', '0.9.2'
  gem 'mocha', '0.9.8'
  gem 'shoulda', '2.10.3'
  gem 'bench_press'
end

