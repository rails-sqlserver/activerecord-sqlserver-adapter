# frozen_string_literal: true

require 'openssl'
source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

gem "sqlite3", "~> 1.4"
gem "pg", ">= 0.18.0"

gem 'bcrypt'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

if RbConfig::CONFIG["host_os"] =~ /darwin/
  gem 'terminal-notifier-guard'
end

if ENV['RAILS_SOURCE']
  gemspec path: ENV['RAILS_SOURCE']
else
  # Need to get rails source because the gem doesn't include tests
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
  gem 'rails', github: "aidanharan/rails", branch: "isolation-debug"
end

if ENV['AREL']
  gem 'arel', path: ENV['AREL']
end

group :tinytds do
  if ENV['TINYTDS_SOURCE']
    gem 'tiny_tds', path: ENV['TINYTDS_SOURCE']
  elsif ENV['TINYTDS_VERSION']
    gem 'tiny_tds', ENV['TINYTDS_VERSION']
  else
    gem 'tiny_tds'
  end
end

group :development do
  gem 'byebug', platform: [:mri, :mingw, :x64_mingw]
  gem 'mocha'
  gem 'minitest-spec-rails'
end

group :guard do
  gem 'guard'
  gem 'guard-minitest'
end
