
source :rubygems

gemspec :path => ENV['RAILS_SOURCE']
gem 'arel', :path => ENV['AREL'] if ENV['AREL']


group :development do
  gem 'rake', '>= 0.8.7'
  gem 'mocha', '>= 0.9.8'
  gem 'shoulda', '>= 2.10.3'
  platforms :mri_18 do
    gem "ruby-debug", ">= 0.10.3"
  end
end

