require 'rubygems'
require 'rake'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'

PKG_NAME = 'activerecord-sqlserver-adapter'
PKG_BUILD = ".#{ENV['PKG_BUILD']}" if ENV['PKG_BUILD']
PKG_VERSION = "1.0.0#{PKG_BUILD}"

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.summary = 'SQL Server adapter for Active Record'
  s.version = PKG_VERSION

  s.add_dependency 'activerecord', '>= 1.15.3.7707'
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
