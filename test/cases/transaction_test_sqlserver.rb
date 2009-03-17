require 'cases/sqlserver_helper'
require 'models/bird'
require 'models/developer'

class TransactionTestSqlserver < ActiveRecord::TestCase
  
  self.use_transactional_fixtures = false
  
  setup :delete_birds
  
  context 'Testing transaction basics' do
    
    should 'allow ActiveRecord::Rollback to work in 1 transaction block' do
      Bird.transaction do
        Bird.create! :name => 'Crow', :pirate_id => 1
        raise ActiveRecord::Rollback
      end
      assert_no_birds
    end
    
    should 'allow nested transactions to totally rollback' do
      begin
        Bird.transaction do
          Bird.create! :name => 'Crow', :pirate_id => 1
          Bird.transaction do
            Bird.create! :name => 'Dog', :pirate_id => 1
            raise 'HELL'
          end
        end
      rescue Exception => e
        assert_no_birds
      end
    end

  end
  
  context 'Testing #outside_transaction?' do
  
    should 'work in simple usage' do
      assert Bird.connection.outside_transaction?
      Bird.connection.begin_db_transaction
      assert !Bird.connection.outside_transaction?
      Bird.connection.rollback_db_transaction
      assert Bird.connection.outside_transaction?
    end
    
    should 'work inside nested transactions' do
      assert Bird.connection.outside_transaction?
      Bird.transaction do
        assert !Bird.connection.outside_transaction?
        Bird.transaction do
          assert !Bird.connection.outside_transaction?
        end
      end
      assert Bird.connection.outside_transaction?
    end
    
    should 'not call rollback if no transaction is active' do
      assert_raise RuntimeError do
        Bird.transaction do
          Bird.connection.rollback_db_transaction
          Bird.connection.expects(:rollback_db_transaction).never
          raise "Rails doesn't scale!"
        end
      end
    end
    
    should 'test_open_transactions_count_is_reset_to_zero_if_no_transaction_active' do
      Bird.transaction do
        Bird.transaction do
          Bird.connection.rollback_db_transaction
        end
        assert_equal 0, Bird.connection.open_transactions
      end
      assert_equal 0, Bird.connection.open_transactions
    end
    
  end
  
  
  
  protected
  
  def delete_birds
    Bird.delete_all
  end
  
  def assert_no_birds
    assert Bird.count.zero?, "Expected Bird to have no models but it did have:\n#{Bird.all.inspect}"
  end
  
end

