
source :rubygems

if ENV['RAILS_SOURCE']
  gemspec :path => ENV['RAILS_SOURCE']
else
  version = ENV['RAILS_VERSION'] || begin
    require 'net/http'
    spec = eval(File.read('activerecord-sqlserver-adapter.gemspec'))
    version = spec.dependencies.detect{ |d|d.name == 'activerecord' }.requirement.requirements.first.last.version
    major, minor, tiny = version.split('.')
    uri = URI.parse "http://rubygems.org/api/v1/versions/activerecord.yaml"
    YAML.load(Net::HTTP.get(uri)).select do |data|
      a, b, c = data['number'].split('.')
      !data['prerelease'] && major == a && minor == b
    end.first['number']
  end
  gem 'rails', :git => "git://github.com/rails/rails.git", :tag => "v#{version}"
end

if ENV['AREL']
  gem 'arel', :path => ENV['AREL']
end

group :tinytds do
  if ENV['TINYTDS_SOURCE']
    gem 'tiny_tds', :path => ENV['TINYTDS_SOURCE']
  else
    gem 'tiny_tds', '0.5.1'
  end
end

group :odbc do
  gem 'ruby-odbc'
end

group :development do
  gem 'bcrypt-ruby', '~> 3.0.0'
  gem 'rake', '0.9.2'
  gem 'mocha', '0.9.8'
  gem 'shoulda', '2.10.3'
  gem 'bench_press'
  gem 'nokogiri'
end

