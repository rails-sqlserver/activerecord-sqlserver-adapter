require 'cases/sqlserver_helper'
require 'models/ship'
require 'models/developer'

class TransactionTestSqlserver < ActiveRecord::TestCase

  self.use_transactional_fixtures = false

  setup :delete_ships

  context 'Testing transaction basics' do

    should 'allow ActiveRecord::Rollback to work in 1 transaction block' do
      Ship.transaction do
        Ship.create! name: 'Black Pearl'
        raise ActiveRecord::Rollback
      end
      assert_no_ships
    end

    should 'allow nested transactions to totally rollback' do
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

  end

  protected

  def delete_ships
    Ship.delete_all
  end

  def assert_no_ships
    assert Ship.count.zero?, "Expected Ship to have no models but it did have:\n#{Ship.all.inspect}"
  end

end

class TransactionTest < ActiveRecord::TestCase
  include SqlserverCoercedTest

  COERCED_TESTS = [:test_releasing_named_savepoints]

  def test_coerced_releasing_named_savepoints
    Topic.transaction do
      Topic.connection.create_savepoint("another")
      Topic.connection.release_savepoint("another")

      # The origin rails test tries to re-release the savepoint, but
      # since sqlserver doesn't have the concept of releasing, it doesn't
      # fail, so we just omit that part here
    end
  end
end
