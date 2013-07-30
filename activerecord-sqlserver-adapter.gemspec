# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.platform      = Gem::Platform::RUBY
  s.name          = "activerecord-sqlserver-adapter"
  s.version       = File.read(File.expand_path("../VERSION",__FILE__)).strip
  s.summary       = "ActiveRecord SQL Server Adapter. For SQL Server 2005 And Higher."
  s.description   = "ActiveRecord SQL Server Adapter. For SQL Server 2005 And Higher."

  s.authors       = ['Ken Collins', 'Murray Steele', 'Shawn Balestracci', 'Joe Rafaniello', 'Tom Ward']
  s.email         = "ken@metaskills.net"
  s.homepage      = "http://github.com/rails-sqlserver/activerecord-sqlserver-adapter"

  s.files         = Dir['CHANGELOG', 'MIT-LICENSE', 'README.rdoc', 'VERSION', 'lib/**/*' ]
  s.require_path  = 'lib'
  s.rubyforge_project = 'activerecord-sqlserver-adapter'

  s.add_dependency('activerecord', '~> 4.0.0.beta')
end

