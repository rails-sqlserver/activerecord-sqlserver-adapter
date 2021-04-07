# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/book"

class InsertAllTestSQLServer < ActiveRecord::TestCase
  fixtures :books

  # Issue https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/issues/847
  it "execute insert_all with a single element" do
    assert_difference "Book.count", +1 do
      Book.insert_all [{ name: "Rework", author_id: 1 }]
    end
  end
end
