require 'bundler/setup'
Bundler.require :default, :development, :test
# require 'guard'
# require 'guard-minitest'
# require 'minitest'
# require 'minitest-focus'
# require 'minitest-spec-rails'
# require 'mocha'
# require 'nokogiri'
# require 'byebug'
# require 'rake'
require 'tiny_tds'

c = TinyTds::Client.new(
  host: ENV['CI_AZURE_HOST'],
  username: 'rails',
  password: ENV['CI_AZURE_PASS'],
  database: 'activerecord_unittest',
  azure: true
)

puts c.execute("SELECT 1 AS [one]").each
c.close
