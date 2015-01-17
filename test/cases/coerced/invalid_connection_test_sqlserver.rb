require 'cases/helper_sqlserver'
require 'cases/invalid_connection_test'

class TestAdapterWithInvalidConnection < ActiveRecord::TestCase
   def setup
    #The activerecord test arbitrarily used mysql (needed to use somthing that wasn't sqlite).
    #It makes much more sense for us to use sqlserver
    Bird.establish_connection adapter: 'sqlserver', database: 'i_do_not_exist'
  end
end
