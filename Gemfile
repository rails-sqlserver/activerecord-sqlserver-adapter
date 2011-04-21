
source :rubygems

gemspec :path => ENV['RAILS_SOURCE']
# TODO: [Rails31] Remove this rack hack.
gem 'rack', :git => 'git://github.com/rack/rack.git'  # master e8563a6 2011-03-30
gem 'arel', :path => ENV['AREL']

group :tinytds do
  if ENV['TINYTDS_SOURCE']
    gem 'tiny_tds', :path => ENV['TINYTDS_SOURCE']
  else
    gem 'tiny_tds'
  end
end

group :odbc do
  gem 'ruby-odbc'
end

group :development do
  gem 'rake', '>= 0.8.7'
  gem 'mocha', '0.9.8'
  gem 'shoulda', '2.10.3'
  platforms :mri_18 do
    gem 'ruby-prof', '0.9.1'
    gem 'ruby-debug', '0.10.3'
  end
end

