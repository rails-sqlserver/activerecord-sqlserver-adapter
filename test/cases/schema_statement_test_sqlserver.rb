require 'cases/sqlserver_helper'

class SchemaStatementTestSqlserver < ActiveRecord::TestCase

  def setup
    @connection = ActiveRecord::Base.connection
  end
  
  context 'For #columns' do
    
    # Remove brackets and outer quotes (if quoted) of default value returned by db, i.e:
    #   "(1)" => "1", "('1')" => "1", "((-1))" => "-1", "('(-1)')" => "(-1)"
    #   Unicode strings will be prefixed with an N. Remove that too.
    
    # SQL Server only supports limits on *char and float types
    # although for schema dumping purposes it's useful to know that (big|small)int are 2|8 respectively.
    
    should 'description' do
      
    end

  end
  
  
end
