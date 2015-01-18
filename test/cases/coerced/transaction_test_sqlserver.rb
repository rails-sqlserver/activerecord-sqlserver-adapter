require 'cases/helper_sqlserver'

class TransactionTest < ActiveRecord::TestCase
  include ARTest::SQLServer::CoercedTest

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
