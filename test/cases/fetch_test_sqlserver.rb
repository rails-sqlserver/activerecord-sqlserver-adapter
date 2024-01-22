# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/book"

class FetchTestSqlserver < ActiveRecord::TestCase
  let(:books) { @books }

  before { create_10_books }

  it "work with fully qualified table and columns in select" do
    books = Book.select("books.id, books.name").limit(3).offset(5)
    assert_equal Book.all[5, 3].map(&:id), books.map(&:id)
  end

  describe "count" do
    it "gauntlet" do
      books[0].destroy
      books[1].destroy
      books[2].destroy
      assert_equal 7, Book.count
      assert_equal 1, Book.limit(1).offset(1).count
      assert_equal 1, Book.limit(1).offset(5).count
      assert_equal 1, Book.limit(1).offset(6).count
      assert_equal 0, Book.limit(1).offset(7).count
      assert_equal 3, Book.limit(3).offset(4).count
      assert_equal 2, Book.limit(3).offset(5).count
      assert_equal 1, Book.limit(3).offset(6).count
      assert_equal 0, Book.limit(3).offset(7).count
      assert_equal 0, Book.limit(3).offset(8).count
    end
  end

  describe "order" do
    it "gauntlet" do
      Book.where(name: "Name-10").delete_all
      _(Book.order(:name).limit(1).offset(1).map(&:name)).must_equal ["Name-2"]
      _(Book.order(:name).limit(2).offset(2).map(&:name)).must_equal ["Name-3", "Name-4"]
      _(Book.order(:name).limit(2).offset(7).map(&:name)).must_equal ["Name-8", "Name-9"]
      _(Book.order(:name).limit(3).offset(7).map(&:name)).must_equal ["Name-8", "Name-9"]
      _(Book.order(:name).limit(3).offset(9).map(&:name)).must_equal []
    end
  end

  describe "FROM subquery" do
    let(:from_sql) { "(SELECT [books].* FROM [books]) [books]" }

    it "SQL generated correctly for FROM subquery if order provided" do
      query = Book.from(from_sql).order(:id).limit(5)

      assert_equal query.to_sql, "SELECT [books].* FROM (SELECT [books].* FROM [books]) [books] ORDER BY [books].[id] ASC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY"
      assert_equal query.to_a.count, 5
    end

    it "exception thrown if FROM subquery is provided without an order" do
      query = Book.from(from_sql).limit(5)

      assert_raise(ActiveRecord::StatementInvalid) do
        query.to_sql
      end
    end
  end

  protected

  def create_10_books
    Book.delete_all
    @books = (1..10).map { |i| Book.create! name: "Name-#{i}" }
  end
end

class DeterministicFetchWithCompositePkTestSQLServer < ActiveRecord::TestCase
  it "orders by the identity column if table has one" do
    SSCompositePkWithIdentity.delete_all
    SSCompositePkWithIdentity.create(pk_col_two: 2)
    SSCompositePkWithIdentity.create(pk_col_two: 1)

    _(SSCompositePkWithIdentity.take(1).map(&:pk_col_two)).must_equal [2]
  end

  it "orders by the first column if table has no identity column" do
    SSCompositePkWithoutIdentity.delete_all
    SSCompositePkWithoutIdentity.create(pk_col_one: 2, pk_col_two: 2)
    SSCompositePkWithoutIdentity.create(pk_col_one: 1, pk_col_two: 1)

    _(SSCompositePkWithoutIdentity.take(1).map(&:pk_col_two)).must_equal [1]
  end
end
