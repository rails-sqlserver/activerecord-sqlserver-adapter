require 'profile/helper'
require 'models/topic'
require 'models/reply'

class ProfileConnectionCase < ActiveRecord::TestCase
  
  fixtures :topics
  
  def setup
    @connection = ActiveRecord::Base.connection
  end
  
  def test_select
    ruby_profile :connection_select do
      1000.times { @connection.send :select, "SELECT [topics].* FROM [topics]" }
    end
  end
  
  
end


