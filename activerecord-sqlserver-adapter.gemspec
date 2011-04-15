
Gem::Specification.new do |s|
  s.platform      = Gem::Platform::RUBY
  s.name          = "activerecord-sqlserver-adapter"
  s.version       = "3.0.14"
  s.summary       = "SQL Server 2005 and 2008 Adapter For ActiveRecord."
  s.description   = "SQL Server 2005 and 2008 Adapter For ActiveRecord"
  
  s.authors       = ['Ken Collins', 'Murray Steele', 'Shawn Balestracci', 'Joe Rafaniello', 'Tom Ward']
  s.email         = "ken@metaskills.net"
  s.homepage      = "http://github.com/rails-sqlserver/activerecord-sqlserver-adapter"
  
  s.files         = Dir['CHANGELOG', 'MIT-LICENSE', 'README.rdoc', 'lib/**/*' ]
  s.require_path  = 'lib'
  s.has_rdoc      = true
  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options.concat ['--main',  'README.rdoc']
  s.rubyforge_project = 'activerecord-sqlserver-adapter'
  
  s.add_dependency('activerecord', '~> 3.0.3')
  s.add_dependency('arel', '~> 2.0.7')
end

