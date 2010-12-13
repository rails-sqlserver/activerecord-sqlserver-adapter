
source :rubygems

gem 'tiny_tds', :path => ENV['TINYTDS_SOURCE'] if ENV['TINYTDS_SOURCE']

group :odbc do
  gem 'ruby-odbc', '0.99992'
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

