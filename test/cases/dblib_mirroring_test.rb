#For dblib connection mode define database mirroring server with :dataserver_mirror key in database.yml. 
#Example:
configuration = {
  :adapter           => 'sqlserver',
  :mode              => 'dblib',
  :dataserver        => ENV['ACTIVERECORD_UNITTEST_DATASERVER_PRIMARY'],
  :username          => ENV['ACTIVERECORD_UNITTEST_USER'] || 'rails',
  :password          => ENV['ACTIVERECORD_UNITTEST_PASS'] || '',
  :database          => 'activerecord_unittest_mirroring',
  :appname           => 'SQLServerAdptrUnit',
  :azure             => false,
  :mirror            => { 
    :dataserver => ENV['ACTIVERECORD_UNITTEST_DATASERVER_MIRROR']
  }
}

require 'cases/sqlserver_helper' 
ActiveRecord::Base.configurations = ActiveRecord::Base.configurations = {'mirroring' => configuration}
require 'cases/mirroring_test.rb'
