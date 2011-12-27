require 'cases/sqlserver_helper'
require 'models/person'
require 'models/reader'

class PessimisticLockingTestSqlserver < ActiveRecord::TestCase
  
  self.use_transactional_fixtures = false
  fixtures :people, :readers
  
  def setup
    Person.columns; Reader.columns # Avoid introspection queries during tests.
  end
  
  context 'For simple finds with default lock option' do

    should 'lock with simple find' do
      assert_nothing_raised do
        Person.transaction do
          Person.find 1, :lock => true
        end
      end
    end

    should 'lock with scoped find' do
      assert_nothing_raised do
        Person.transaction do
          Person.send(:with_scope, :find => { :lock => true }) do
            Person.find 1
          end
        end
      end
    end

    should 'lock with eager find' do
      assert_nothing_raised do
        Person.transaction do
          Person.find 1, :include => :readers, :lock => true
        end
      end
    end

    should 'reload with lock when #lock! called' do
      assert_nothing_raised do
        Person.transaction do
          person = Person.find 1
          old, person.first_name = person.first_name, 'fooman'
          person.lock!
          assert_equal old, person.first_name
        end
      end
    end
    
    should 'simply add lock to find all' do
      assert_sql %r|SELECT \[people\]\.\* FROM \[people\] WITH \(NOLOCK\)| do
        Person.all(:lock => 'WITH (NOLOCK)')
      end
    end

  end
  
  context 'For paginated finds' do
    
    setup do
      20.times { |n| Person.create!(:first_name => "Thing_#{n}") }
    end
    
    should 'cope with eager loading un-locked paginated' do
      eager_ids_sql = /SELECT TOP \(5\).*FROM \[people\] WITH \(NOLOCK\)/
      loader_sql = /FROM \[people\] WITH \(NOLOCK\).*WHERE \[people\]\.\[id\] IN/
      assert_sql(eager_ids_sql,loader_sql) do
        Person.all(:include => :readers, :lock => 'WITH (NOLOCK)', :limit => 5, :offset => 10)
      end
    end
    
  end
  
  
end
