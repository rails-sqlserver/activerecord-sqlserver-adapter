require 'cases/sqlserver_helper'
require 'models/company'
require 'models/topic'
require 'models/edge'
require 'models/club'
require 'models/organization'

class ScratchTestSqlserver < ActiveRecord::TestCase

  fixtures :companies, :accounts, :topics
  
  should 'pass' do
    assert_equal Company.count(:all), Company.count(:all, :from => 'companies')
    assert_equal Account.count(:all, :conditions => "credit_limit = 50"),
        Account.count(:all, :from => 'accounts', :conditions => "credit_limit = 50")
    assert_equal Company.count(:type, :conditions => {:type => "Firm"}),
        Company.count(:type, :conditions => {:type => "Firm"}, :from => 'companies')
  end
  
  
  
end

