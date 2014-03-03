require 'cases/sqlserver_helper'
require 'models/owner'

class HasManyThroughAssociationsTest <  ActiveRecord::TestCase
  COERCED_TESTS = [:test_has_many_through_obeys_order_on_through_association]
  # Rails does not do a case-insensive comparison
  # Until that patch is made to rails we are preventing this test from running in this gem.

  include SqlserverCoercedTest
  def test_coerced_has_many_through_obeys_order_on_through_association
    owner = owners(:blackbeard)
    # assert owner.toys.to_sql.include?("pets.name desc") # What's currently in rails
    assert owner.toys.to_sql.downcase.include?("pets.name desc")
    assert_equal ["parrot", "bulbul"], owner.toys.map { |r| r.pet.name }
  end
end
