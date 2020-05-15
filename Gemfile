# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

gem "bcrypt"
gem "pg",      ">= 0.18.0"
gem "sqlite3", "~> 1.4"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

if ENV["RAILS_SOURCE"]
  gemspec path: ENV["RAILS_SOURCE"]
else
  # Need to get rails source because the gem doesn't include tests
  version = ENV["RAILS_VERSION"] || begin
    require "openssl"
    require "net/http"
    require "yaml"

    spec = eval(File.read("activerecord-sqlserver-adapter.gemspec"))
    ver  = spec.dependencies.detect { |d| d.name == "activerecord" }.requirement.requirements.first.last.version
    major, minor, _tiny, pre = ver.split(".")

    if pre
      ver
    else
      uri  = URI.parse("https://rubygems.org/api/v1/versions/activerecord.yaml")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      YAML.load(http.request(Net::HTTP::Get.new(uri.request_uri)).body).find do |data|
        a, b, = data["number"].split(".")
        !data["prerelease"] && major == a && (minor.nil? || minor == b)
      end["number"]
    end
  end
  gem "rails", github: "rails/rails", tag: "v#{version}"
end

# rubocop:disable Bundler/DuplicatedGem
group :tinytds do
  if ENV["TINYTDS_SOURCE"]
    gem "tiny_tds", path: ENV["TINYTDS_SOURCE"]
  elsif ENV["TINYTDS_VERSION"]
    gem "tiny_tds", ENV["TINYTDS_VERSION"]
  else
    gem "tiny_tds"
  end
end
# rubocop:enable Bundler/DuplicatedGem

group :development do
  gem "minitest-spec-rails"
  gem "mocha"
  gem "pry-byebug", platform: [:mri, :mingw, :x64_mingw]
end

group :guard do
  gem "guard"
  gem "guard-minitest"
  gem "terminal-notifier-guard" if RbConfig::CONFIG["host_os"] =~ /darwin/
end

group :rubocop do
  gem "rubocop", require: false
end
