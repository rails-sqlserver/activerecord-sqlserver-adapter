
source :rubygems

gemspec :path => ENV['RAILS_SOURCE']
gem 'arel', '~> 2.1.4'

if ENV['AREL']
  gem 'arel', :path => ENV['AREL']
end

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
  gem 'bench_press'
  platforms :mri_18 do
    gem 'ruby-prof', '0.9.1'
    gem 'ruby-debug', '0.10.3'
  end
  platforms :mri_19 do
    gem 'ruby-debug19', '0.11.6'
  end
end

