#cases/invalid_connection_test was added in rails 4.0.1
if Pathname.new('cases/invalid_connection_test').exist?
  require 'cases/sqlserver_helper'
  require 'cases/invalid_connection_test'

  class TestAdapterWithInvalidConnection < ActiveRecord::TestCase  
     def setup
      #The activerecord test arbitrarily used mysql (needed to use somthing that wasn't sqlite).
      #It makes much more sense for us to use sqlserver
      Bird.establish_connection adapter: 'sqlserver', database: 'i_do_not_exist'
    end
  end
end
