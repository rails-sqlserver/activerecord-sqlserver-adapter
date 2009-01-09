require 'rubygems'
require 'rake'
require 'rake/testtask'


desc 'Create the SQL Server test databases'
task :create_databases do
  # Define a user named 'rails' in SQL Server with all privileges granted
  # Use an empty password for user 'rails', or alternatively use the OSQLPASSWORD environment variable
  # which allows you to set a default password for the current session.
  %x( osql -S localhost -U rails -Q "create database activerecord_unittest" -P )
  %x( osql -S localhost -U rails -Q "create database activerecord_unittest2" -P )
  %x( osql -S localhost -U rails -d activerecord_unittest -Q "exec sp_grantdbaccess 'rails'" -P )
  %x( osql -S localhost -U rails -d activerecord_unittest2 -Q "exec sp_grantdbaccess 'rails'" -P ) 
  %x( osql -S localhost -U rails -d activerecord_unittest -Q "grant BACKUP DATABASE, BACKUP LOG, CREATE DEFAULT, CREATE FUNCTION, CREATE PROCEDURE, CREATE RULE, CREATE TABLE, CREATE VIEW to 'rails';" -P )
  %x( osql -S localhost -U rails -d activerecord_unittest2 -Q "grant BACKUP DATABASE, BACKUP LOG, CREATE DEFAULT, CREATE FUNCTION, CREATE PROCEDURE, CREATE RULE, CREATE TABLE, CREATE VIEW to 'rails';" -P )
end

desc 'Drop the SQL Server test databases'
task :drop_databases do
  %x( osql -S localhost -U rails -Q "drop database activerecord_unittest" -P )
  %x( osql -S localhost -U rails -Q "drop database activerecord_unittest2" -P )
end

desc 'Recreate the SQL Server test databases'
task :recreate_databases => [:drop_databases, :create_databases]


for adapter in %w( sqlserver sqlserver_odbc )
  
  Rake::TestTask.new("test_#{adapter}") { |t|
    t.libs << "test" 
    t.libs << "test/connections/native_#{adapter}"
    t.libs << "../../../rails/activerecord/test/"
    t.test_files = (
      Dir.glob("test/cases/**/*_test_sqlserver.rb").sort + 
      Dir.glob("../../../rails/activerecord/test/**/*_test.rb").sort )
    t.verbose = true
  }

  namespace adapter do
    task :test => "test_#{adapter}"
  end
  
end

desc 'Test with unicode types enabled.'
Rake::TestTask.new(:test_unicode_types) do |t|
  ENV['ENABLE_DEFAULT_UNICODE_TYPES'] = 'true'
  test = Rake::Task['test_sqlserver_odbc']
  test.invoke
end
