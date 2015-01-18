require 'cases/helper_sqlserver'
require 'models/ship'
require 'models/developer'

class TransactionTestSQLServer < ActiveRecord::TestCase

  self.use_transactional_fixtures = false

  before { delete_ships }

  it 'allow ActiveRecord::Rollback to work in 1 transaction block' do
    Ship.transaction do
      Ship.create! name: 'Black Pearl'
      raise ActiveRecord::Rollback
    end
    assert_no_ships
  end

  it 'allow nested transactions to totally rollback' do
    begin
      Ship.transaction do
        Ship.create! name: 'Black Pearl'
        Ship.transaction do
          Ship.create! name: 'Flying Dutchman'
          raise 'HELL'
        end
      end
    rescue Exception => e
      assert_no_ships
    end
  end


  protected

  def delete_ships
    Ship.delete_all
  end

  def assert_no_ships
    assert Ship.count.zero?, "Expected Ship to have no models but it did have:\n#{Ship.all.inspect}"
  end

end
