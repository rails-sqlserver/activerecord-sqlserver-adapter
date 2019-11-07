require 'cases/helper_sqlserver'
require 'models/book'

class FetchTestSqlserver < ActiveRecord::TestCase

  let(:books) { @books }

  before { create_10_books }

  it 'work with fully qualified table and columns in select' do
    books = Book.select('books.id, books.name').limit(3).offset(5)
    assert_equal Book.all[5,3].map(&:id), books.map(&:id)
  end

  describe 'count' do

    it 'gauntlet' do
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

  describe 'order' do

    it 'gauntlet' do
      Book.where(name:'Name-10').delete_all
      _(Book.order(:name).limit(1).offset(1).map(&:name)).must_equal ['Name-2']
      _(Book.order(:name).limit(2).offset(2).map(&:name)).must_equal ['Name-3', 'Name-4']
      _(Book.order(:name).limit(2).offset(7).map(&:name)).must_equal ['Name-8', 'Name-9']
      _(Book.order(:name).limit(3).offset(7).map(&:name)).must_equal ['Name-8', 'Name-9']
      _(Book.order(:name).limit(3).offset(9).map(&:name)).must_equal []
    end

  end


  protected

  def create_10_books
    Book.delete_all
    @books = (1..10).map { |i| Book.create! name: "Name-#{i}" }
  end

end

