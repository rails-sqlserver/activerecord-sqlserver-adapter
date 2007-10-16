print "Using native SQLServer\n"
require_dependency 'fixtures/course'
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.configurations = {
  'arunit' => {
    :adapter  => 'sqlserver',
    :host     => 'localhost',
    :username => 'rails',
    :database => 'activerecord_unittest'
  },
  'arunit2' => {
    :adapter  => 'sqlserver',
    :host     => 'localhost',
    :username => 'rails',
    :database => 'activerecord_unittest2'
  }
}

ActiveRecord::Base.establish_connection 'arunit'
Course.establish_connection 'arunit2'
print "Using native SQLServer\n"
require_dependency 'fixtures/course'
require 'logger'

ActiveRecord::Base.logger = Logger.new("debug.log")

ActiveRecord::Base.configurations = {
  'arunit' => {
    :adapter  => 'sqlserver',
    :host     => 'localhost',
    :username => 'rails',
    :database => 'activerecord_unittest'
  },
  'arunit2' => {
    :adapter  => 'sqlserver',
    :host     => 'localhost',
    :username => 'rails',
    :database => 'activerecord_unittest2'
  }
}

ActiveRecord::Base.establish_connection 'arunit'
Course.establish_connection 'arunit2'
