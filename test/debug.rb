require 'tiny_tds'
sleep 5
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' ; Bundler.require :default, :development

c = TinyTds::Client.new(
  host: ENV['CI_AZURE_HOST'],
  username: 'rails',
  password: ENV['CI_AZURE_PASS'],
  database: 'activerecord_unittest',
  azure: true,
  login_timeout: 20,
  tds_version: '7.3'
)

puts c.execute("SELECT 1 AS [one]").each
c.close
