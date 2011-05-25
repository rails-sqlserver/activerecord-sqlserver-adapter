require 'pp'
#define model
class Programmer < ActiveRecord::Base 
end                

Programmer.establish_connection 'mirroring'

#dummy class to include SqlServerMirroring module, and test it
class ForMirroringTests
  include ActiveRecord::ConnectionAdapters::SqlServerMirroring

  def initialize(options)
    @connection_options = options
  end

  attr_reader :connection_options
end

class MirroringTestSqlserver < ActiveRecord::TestCase
  
  def setup        
    create_database_schema    
  end 

  private 

  def create_database_schema    
    ActiveRecord::Schema.define do
      
      Programmer.connection.create_table :programmers, :force => true do |t|
        t.column :first_name, :string
        t.column :last_name, :string
      end
      
    end  
  end     

  def db_failover
    Programmer.connection.execute("use master; ALTER DATABASE activerecord_unittest_mirroring SET PARTNER FAILOVER") 
  end
  
  def failover                    
    begin
      db_failover
    rescue 
      sleep 1
      retry
    end
    Programmer.connection.reconnect!
    print_current_server_name
  end         
  
  def print_current_server_name
    print "connected to #{Programmer.server_name}\n"
  end

  public 

  def test_create    
    print_current_server_name
    Programmer.create(:first_name => "Sasa",  :last_name => "Juric")
    assert_equal 1, Programmer.count                                                          
    
    failover
    
    Programmer.create(:first_name => "Goran",  :last_name => "Pizent")    
    assert_equal 2, Programmer.count
    
    failover
    
    Programmer.create(:first_name => "Vedran",  :last_name => "Skrnjug")    
    assert_equal 3, Programmer.count    
  end

  def test_status_flags
    assert Programmer.db_mirroring_active?
  end
  
  def test_status_flags_without_mirroring
    assert !Topic.db_mirroring_active?
    assert !Topic.db_mirroring_synchronized?
  end

  def test_mirroring_status
    status = Programmer.db_mirroring_status
    assert !status.empty?
    assert_equal "activerecord_unittest_mirroring", status["database_name"]
    assert_equal "PRINCIPAL", status["mirroring_role_desc"]
    assert ["SYNCHRONIZED", "SYNCHRONIZING"].include? status["mirroring_state_desc"]
  end

  def test_mirroring_status_without_mirroring
    assert Topic.db_mirroring_status.empty?
  end

  def test_switch_to_mirror
    fmt = ForMirroringTests.new({  
      :adapter => :sqlserver,
      :mode => :dblib,
      :username => "sa",
      :password => "cheese",
      :database => "db_name",
      :host => "primary_server",
      :mirror => {
        :host => "mirror_server",
        :port => 1434,
        :password => "mouse"
      }
    })    
    
    fmt.send(:switch_to_mirror)
    options = fmt.connection_options
    assert_equal "mirror_server", options[:host]
    assert_equal 1434, options[:port]
    assert_equal "mouse", options[:password]

    assert_equal :sqlserver, options[:adapter]
    assert_equal :dblib, options[:mode]
    assert_equal "sa", options[:username]
    assert_equal "db_name", options[:database]

    fmt.send(:switch_to_mirror)
    options = fmt.connection_options
    assert_equal "primary_server", options[:host]
    assert_nil   options[:port]
    assert_equal "cheese", options[:password]

    assert_equal :sqlserver, options[:adapter]
    assert_equal :dblib, options[:mode]
    assert_equal "sa", options[:username]
    assert_equal "db_name", options[:database]    
  end

end
