
source :rubygems

gemspec :path => ENV['RAILS_SOURCE']

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
  gem 'rake', '>= 0.8.7'
  gem 'mocha', '0.9.8'
  gem 'shoulda', '2.10.3'
  gem 'bench_press'
end

