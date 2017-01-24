
source 'https://rubygems.org'

if ENV['RAILS_SOURCE']
  gemspec path: ENV['RAILS_SOURCE']
else
  # Need to get rails source beacause the gem doesn't include tests
  version = ENV['RAILS_VERSION'] || begin
    require 'net/http'
    require 'yaml'
    spec = eval(File.read('activerecord-sqlserver-adapter.gemspec'))
    ver = spec.dependencies.detect{ |d|d.name == 'activerecord' }.requirement.requirements.first.last.version
    major, minor, tiny, pre = ver.split('.')
    if !pre
      uri = URI.parse "https://rubygems.org/api/v1/versions/activerecord.yaml"
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      YAML.load(http.request(Net::HTTP::Get.new(uri.request_uri)).body).select do |data|
        a, b, c = data['number'].split('.')
        !data['prerelease'] && major == a && (minor.nil? || minor == b)
      end.first['number']
    else
      ver
    end
  end
  gem 'rails', git: "git://github.com/rails/rails.git", tag: "v#{version}"
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

