# require 'rails/all'
require 'tiny_tds'

c = TinyTds::Client.new(
  host: ENV['CI_AZURE_HOST'],
  username: 'rails',
  password: ENV['CI_AZURE_PASS'],
  database: 'activerecord_unittest',
  azure: true,
  tds_version: '7.3'
)

puts c.execute("SELECT 1 AS [one]").each
c.close
