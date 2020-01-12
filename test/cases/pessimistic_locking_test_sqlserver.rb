require 'cases/helper_sqlserver'
require 'models/person'
require 'models/reader'

class PessimisticLockingTestSQLServer < ActiveRecord::TestCase

  fixtures :people, :readers

  before do
    Person.columns
    Reader.columns
  end

  it 'uses with updlock by default' do
    assert_sql %r|SELECT \[people\]\.\* FROM \[people\] WITH\(UPDLOCK\)| do
      _(Person.lock(true).to_a).must_equal Person.all.to_a
    end
  end

  describe 'For simple finds with default lock option' do

    it 'lock with simple find' do
      assert_nothing_raised do
        Person.transaction do
          _(Person.lock(true).find(1)).must_equal Person.find(1)
        end
      end
    end

    it 'lock with scoped find' do
      assert_nothing_raised do
        Person.transaction do
          Person.lock(true).scoping do
            _(Person.find(1)).must_equal Person.find(1)
          end
        end
      end
    end

    it 'lock with eager find' do
       assert_nothing_raised do
        Person.transaction do
          person = Person.lock(true).includes(:readers).find(1)
          _(person).must_equal Person.find(1)
        end
      end
    end

    it 'can add a custom lock directive' do
      assert_sql %r|SELECT \[people\]\.\* FROM \[people\] WITH\(HOLDLOCK, ROWLOCK\)| do
        Person.lock('WITH(HOLDLOCK, ROWLOCK)').load
      end
    end

    describe 'joining tables' do

      it 'joined tables use updlock by default' do
        assert_sql %r|SELECT \[people\]\.\* FROM \[people\] WITH\(UPDLOCK\) INNER JOIN \[readers\] WITH\(UPDLOCK\)\s+ON \[readers\]\.\[person_id\] = \[people\]\.\[id\]| do
          Person.lock(true).joins(:readers).load
        end
      end

      it 'joined tables can use custom lock directive' do
        assert_sql %r|SELECT \[people\]\.\* FROM \[people\] WITH\(NOLOCK\) INNER JOIN \[readers\] WITH\(NOLOCK\)\s+ON \[readers\]\.\[person_id\] = \[people\]\.\[id\]| do
          Person.lock('WITH(NOLOCK)').joins(:readers).load
        end
      end

      it 'left joined tables use updlock by default' do
        assert_sql %r|SELECT \[people\]\.\* FROM \[people\] WITH\(UPDLOCK\) LEFT OUTER JOIN \[readers\] WITH\(UPDLOCK\)\s+ON \[readers\]\.\[person_id\] = \[people\]\.\[id\]| do
          Person.lock(true).left_joins(:readers).load
        end
      end

      it 'left joined tables can use custom lock directive' do
        assert_sql %r|SELECT \[people\]\.\* FROM \[people\] WITH\(NOLOCK\) LEFT OUTER JOIN \[readers\] WITH\(NOLOCK\)\s+ON \[readers\]\.\[person_id\] = \[people\]\.\[id\]| do
          Person.lock('WITH(NOLOCK)').left_joins(:readers).load
        end
      end

    end

  end

  describe 'For paginated finds' do

    before do
      Person.delete_all
      20.times { |n| Person.create!(first_name: "Thing_#{n}") }
    end

    it 'copes with eager loading un-locked paginated' do
      eager_ids_sql = /SELECT\s+DISTINCT \[people\].\[id\] FROM \[people\] WITH\(UPDLOCK\) LEFT OUTER JOIN \[readers\] WITH\(UPDLOCK\)\s+ON \[readers\].\[person_id\] = \[people\].\[id\]\s+ORDER BY \[people\].\[id\] ASC OFFSET @0 ROWS FETCH NEXT @1 ROWS ONLY/
      loader_sql = /SELECT.*FROM \[people\] WITH\(UPDLOCK\).*WHERE \[people\]\.\[id\] IN/
      assert_sql(eager_ids_sql, loader_sql) do
        people = Person.lock(true).limit(5).offset(10).includes(:readers).references(:readers).to_a
        _(people[0].first_name).must_equal 'Thing_10'
        _(people[1].first_name).must_equal 'Thing_11'
        _(people[2].first_name).must_equal 'Thing_12'
        _(people[3].first_name).must_equal 'Thing_13'
        _(people[4].first_name).must_equal 'Thing_14'
      end
    end

  end

end
