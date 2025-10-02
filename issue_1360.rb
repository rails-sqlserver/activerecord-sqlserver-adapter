require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rails', '~> 7.1.0'
  # gem 'activerecord-sqlserver-adapter', '~> 7.1.11'

  gem 'activerecord-sqlserver-adapter', path: "."
  #
  gem 'tiny_tds'

  gem "pry"
end

require 'active_record'

# Configure database connection
ActiveRecord::Base.establish_connection(
  adapter: 'sqlserver',
  host: 'sqlserver',  # Replace with your SQL Server host
  database: 'activerecord_unittest', # Replace with your database
  username: 'rails',     # Replace with your username
  password: '' # Replace with your password
)

# This should trigger the bug
begin
  puts "Attempting to call use_database as first operation..."
  ActiveRecord::Base.connection.use_database('activerecord_unittest')
  puts "Success: No error occurred"
rescue NoMethodError => e
  puts "BUG REPRODUCED: #{e.message}"
  puts "Error class: #{e.class}"
  puts "Backtrace:"
  puts e.backtrace.first(10)
end

# Workaround: Force connection establishment first
# begin
#   puts "\nTesting workaround - establishing connection first..."
#   ActiveRecord::Base.connection.execute('SELECT 1') # calling something like ActiveRecord::Base.connection.raw_connection _also_ works
#   ActiveRecord::Base.connection.use_database('activerecord_unittest')
#   puts "Workaround successful"
# rescue => e
#   puts "Workaround failed: #{e.message}"
# end
