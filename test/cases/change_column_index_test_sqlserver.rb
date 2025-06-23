# frozen_string_literal: true

require "cases/helper_sqlserver"

class ChangeColumnIndexTestSqlServer < ActiveRecord::TestCase
  class CreateClientsWithUniqueIndex < ActiveRecord::Migration[8.0]
    def up
      create_table :clients do |t|
        t.string :name, limit: 15
      end
      add_index :clients, :name, unique: true
    end

    def down
      drop_table :clients
    end
  end

  class CreateBlogPostsWithMultipleIndexesOnTheSameColumn < ActiveRecord::Migration[8.0]
    def up
      create_table :blog_posts do |t|
        t.string :title, limit: 15
        t.string :subtitle
      end
      add_index :blog_posts, :title, unique: true, where: "([blog_posts].[title] IS NOT NULL)", name: "custom_index_name"
      add_index :blog_posts, [:title, :subtitle], unique: true
    end

    def down
      drop_table :blog_posts
    end
  end

  class ChangeClientsNameLength < ActiveRecord::Migration[8.0]
    def up
      change_column :clients, :name, :string, limit: 30
    end
  end

  class ChangeBlogPostsTitleLength < ActiveRecord::Migration[8.0]
    def up
      change_column :blog_posts, :title, :string, limit: 30
    end
  end

  before do
    @old_verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false

    CreateClientsWithUniqueIndex.new.up
    CreateBlogPostsWithMultipleIndexesOnTheSameColumn.new.up
  end

  after do
    CreateClientsWithUniqueIndex.new.down
    CreateBlogPostsWithMultipleIndexesOnTheSameColumn.new.down

    ActiveRecord::Migration.verbose = @old_verbose
  end

  def test_index_uniqueness_is_maintained_after_column_change
    indexes = ActiveRecord::Base.connection.indexes("clients")
    columns = ActiveRecord::Base.connection.columns("clients")
    assert_equal columns.find { |column| column.name == "name" }.limit, 15
    assert_equal indexes.size, 1
    assert_equal indexes.first.name, "index_clients_on_name"
    assert indexes.first.unique

    ChangeClientsNameLength.new.up

    indexes = ActiveRecord::Base.connection.indexes("clients")
    columns = ActiveRecord::Base.connection.columns("clients")
    assert_equal columns.find { |column| column.name == "name" }.limit, 30
    assert_equal indexes.size, 1
    assert_equal indexes.first.name, "index_clients_on_name"
    assert indexes.first.unique
  end

  def test_multiple_index_options_are_maintained_after_column_change
    indexes = ActiveRecord::Base.connection.indexes("blog_posts")
    columns = ActiveRecord::Base.connection.columns("blog_posts")
    assert_equal columns.find { |column| column.name == "title" }.limit, 15
    assert_equal indexes.size, 2

    index_1 = indexes.find { |index| index.columns == ["title"] }
    assert_equal index_1.name, "custom_index_name"
    assert_equal index_1.where, "([blog_posts].[title] IS NOT NULL)"
    assert index_1.unique

    index_2 = indexes.find { |index| index.columns == ["title", "subtitle"] }
    assert index_2.unique


    ChangeBlogPostsTitleLength.new.up


    indexes = ActiveRecord::Base.connection.indexes("blog_posts")
    columns = ActiveRecord::Base.connection.columns("blog_posts")
    assert_equal columns.find { |column| column.name == "title" }.limit, 30
    assert_equal indexes.size, 2

    index_1 = indexes.find { |index| index.columns == ["title"] }
    assert_equal index_1.name, "custom_index_name"
    assert_equal index_1.where, "([blog_posts].[title] IS NOT NULL)"
    assert index_1.unique

    index_2 = indexes.find { |index| index.columns == ["title", "subtitle"] }
    assert index_2.unique
  end
end
