require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'

PKG_NAME = 'activerecord-sqlserver-adapter'
PKG_BUILD = (".#{ENV['PKG_BUILD']}" if ENV['PKG_BUILD'])
PKG_VERSION = "1.0.0#{PKG_BUILD}"

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.summary = 'SQL Server adapter for Active Record'
  s.version = PKG_VERSION

  s.add_dependency 'activerecord', '>= 1.15.5.7843'
  s.require_path = 'lib'

  s.files = %w(lib/active_record/connection_adapters/sqlserver_adapter.rb)

  s.author = 'Tom Ward'
  s.email = 'tom@popdog.net'
  s.homepage = 'http://wiki.rubyonrails.org/rails/pages/SQL+Server'
  s.rubyforge_project = 'activerecord'
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

desc "Publish the beta gem"
task :pgem => :package do
  Rake::SshFilePublisher.new("davidhh@wrath.rubyonrails.org", "public_html/gems/gems", "pkg", "#{PKG_NAME}-#{PKG_VERSION}.gem").upload
  `ssh davidhh@wrath.rubyonrails.org './gemupdate.sh'`
end

desc "Publish the release files to RubyForge."
task :release => :package do
  require 'rubyforge'

  packages = %w(gem tgz zip).collect{ |ext| "pkg/#{PKG_NAME}-#{PKG_VERSION}.#{ext}" }

  rubyforge = RubyForge.new
  rubyforge.login
  rubyforge.add_release(PKG_NAME, PKG_NAME, "REL #{PKG_VERSION}", *packages)
end


SCHEMA_PATH = File.join(File.dirname(__FILE__), *%w(test fixtures db_definitions))

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
    t.pattern = ["test/**/*_test_sqlserver.rb", "../../../rails/activerecord/test/**/*_test.rb"]
    t.verbose = true
  }

  namespace adapter do
    task :test => "test_#{adapter}"
  end
end
