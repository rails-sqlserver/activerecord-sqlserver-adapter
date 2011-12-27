#For odbc connection mode define database mirroring server with :dsn_mirror key in database.yml. 
#Example:
configuration = {                                                    
  :adapter    => 'sqlserver',
  :mode       => 'ODBC',
  :host       => 'localhost',
  :username   => 'rails',
  :dsn        => ENV['ACTIVERECORD_UNITTEST_DSN_PRIMARY'],
  #    :dsn_mirror => ENV['ACTIVERECORD_UNITTEST_DSN_MIRROR'],
  :database   => 'activerecord_unittest_mirroring',
  :mirror     => { 
    :dsn => ENV['ACTIVERECORD_UNITTEST_DSN_MIRROR']
  }
}

require 'cases/sqlserver_helper' 
ActiveRecord::Base.configurations = ActiveRecord::Base.configurations = {'mirroring' => configuration}
require 'cases/mirroring_test.rb'
