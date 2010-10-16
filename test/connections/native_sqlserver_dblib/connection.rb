print "Using SQLServer via DBLIB\n"
require_dependency 'models/course'
require 'logger'

ActiveRecord::Base.logger = Logger.new(File.expand_path(File.join(SQLSERVER_TEST_ROOT,'debug.log')))
ActiveRecord::Base.logger.level = 0

ActiveRecord::Base.configurations = {
  'arunit' => {
    :adapter    => 'sqlserver',
    :mode       => 'dblib',
    :dataserver => ENV['TINYTDS_UNIT_DATASERVER'],
    :username   => 'rails',
    :password   => '',
    :database   => 'activerecord_unittest',
    :appname    => 'SQLServerUnit'
  },
  'arunit2' => {
    :adapter    => 'sqlserver',
    :mode       => 'dblib',
    :dataserver => ENV['TINYTDS_UNIT_DATASERVER'],
    :username   => 'rails',
    :password   => '',
    :database   => 'activerecord_unittest2',
    :appname    => 'SQLServerUnit2'
  }
}

ActiveRecord::Base.establish_connection 'arunit'
Course.establish_connection 'arunit2'
