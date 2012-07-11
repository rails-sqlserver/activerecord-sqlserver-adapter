# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

version = 

Gem::Specification.new do |s|
  s.platform      = Gem::Platform::RUBY
  s.name          = "activerecord-sqlserver-adapter"
  s.version       = File.read(File.expand_path("../VERSION",__FILE__)).strip
  s.summary       = "SQL Server 2005 and 2008 Adapter For ActiveRecord."
  s.description   = "SQL Server 2005 and 2008 Adapter For ActiveRecord"
  
  s.authors       = ['Ken Collins', 'Murray Steele', 'Shawn Balestracci', 'Joe Rafaniello', 'Tom Ward']
  s.email         = "ken@metaskills.net"
  s.homepage      = "http://github.com/rails-sqlserver/activerecord-sqlserver-adapter"
  
  s.files         = Dir['CHANGELOG', 'MIT-LICENSE', 'README.rdoc', 'VERSION', 'lib/**/*' ]
  s.require_path  = 'lib'
  s.rubyforge_project = 'activerecord-sqlserver-adapter'
  
  s.add_dependency('activerecord', '~> 3.2.0')
end

