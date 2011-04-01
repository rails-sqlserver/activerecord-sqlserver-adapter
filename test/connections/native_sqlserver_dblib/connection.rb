print "Using SQLServer via DBLIB to #{ENV['ACTIVERECORD_UNITTEST_DATASERVER']}\n"
require_dependency 'models/course'
require 'logger'

ActiveRecord::Base.logger = Logger.new(File.expand_path(File.join(SQLSERVER_TEST_ROOT,'debug.log')))
ActiveRecord::Base.logger.level = 0

ActiveRecord::Base.configurations = {
  'arunit' => {
    :adapter    => 'sqlserver',
    :mode       => 'dblib',
    :dataserver => ENV['ACTIVERECORD_UNITTEST_DATASERVER'],
    :username   => ENV['ACTIVERECORD_UNITTEST_USER'] || 'rails',
    :password   => ENV['ACTIVERECORD_UNITTEST_PASS'] || '',
    :database   => 'activerecord_unittest',
    :appname    => 'SQLServerAdptrUnit',
    :azure      => !ENV['ACTIVERECORD_UNITTEST_AZURE'].nil?
  },
  'arunit2' => {
    :adapter    => 'sqlserver',
    :mode       => 'dblib',
    :dataserver => ENV['ACTIVERECORD_UNITTEST_DATASERVER'],
    :username   => ENV['ACTIVERECORD_UNITTEST_USER'] || 'rails',
    :password   => ENV['ACTIVERECORD_UNITTEST_PASS'] || '',
    :database   => 'activerecord_unittest2',
    :appname    => 'SQLServerAdptrUnit2',
    :azure      => !ENV['ACTIVERECORD_UNITTEST_AZURE'].nil?
  }
}

ActiveRecord::Base.establish_connection 'arunit'
Course.establish_connection 'arunit2'
