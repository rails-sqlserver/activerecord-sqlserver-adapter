# encoding: UTF-8
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

  it 'can use an isolation level and reverts back to starting isolation level' do
    in_level = nil
    begin_level = connection.user_options_isolation_level
    begin_level.must_match %r{read committed}i
    Ship.transaction(isolation: :serializable) do
      Ship.create! name: 'Black Pearl'
      in_level = connection.user_options_isolation_level
    end
    after_level = connection.user_options_isolation_level
    in_level.must_match %r{serializable}i
    after_level.must_match %r{read committed}i
  end

  it 'can use an isolation level and reverts back to starting isolation level under exceptions' do
    connection.user_options_isolation_level.must_match %r{read committed}i
    lambda {
      Ship.transaction(isolation: :serializable) { Ship.create! }
    }.must_raise(ActiveRecord::RecordInvalid)
    connection.user_options_isolation_level.must_match %r{read committed}i
  end


  protected

  def delete_ships
    Ship.delete_all
  end

  def assert_no_ships
    assert Ship.count.zero?, "Expected Ship to have no models but it did have:\n#{Ship.all.inspect}"
  end

end
