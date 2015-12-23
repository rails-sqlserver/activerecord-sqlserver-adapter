require 'cases/helper_sqlserver'

class FullyQualifiedIdentifierTestSQLServer < ActiveRecord::TestCase

  describe 'local server' do

    it 'should use table name in select projections' do
      table = Arel::Table.new(:table)
      expected_sql = "SELECT [table].[name] FROM [table]"
      assert_equal expected_sql, table.project(table[:name]).to_sql
    end

  end

  describe 'remote server' do

    before do
      connection_options[:database_prefix] = "[my.server].db.schema."
    end

    after do
      connection_options.delete :database_prefix
    end

    it 'should use fully qualified table name in select from clause' do
      table = Arel::Table.new(:table)
      expected_sql = "SELECT * FROM [my.server].[db].[schema].[table]"
      assert_equal expected_sql, table.project(Arel.star).to_sql
    end

    it 'should not use fully qualified table name in select projections' do
      table = Arel::Table.new(:table)
      expected_sql = "SELECT [table].[name] FROM [my.server].[db].[schema].[table]"
      assert_equal expected_sql, table.project(table[:name]).to_sql
    end

    it 'should not use fully qualified table name in where clause' do
      table = Arel::Table.new(:table)
      expected_sql = "SELECT * FROM [my.server].[db].[schema].[table] WHERE [table].[id] = 42"
      assert_equal expected_sql, table.project(Arel.star).where(table[:id].eq(42)).to_sql
    end

    it 'should not use fully qualified table name in order clause' do
      table = Arel::Table.new(:table)
      expected_sql = "SELECT * FROM [my.server].[db].[schema].[table]  ORDER BY [table].[name]"
      assert_equal expected_sql, table.project(Arel.star).order(table[:name]).to_sql
    end

    it 'should use fully qualified table name in insert statement' do
      manager = Arel::InsertManager.new(Arel::Table.engine)
      manager.into Arel::Table.new(:table)
      manager.values = manager.create_values [Arel.sql('*')], %w{ a }
      expected_sql = "INSERT INTO [my.server].[db].[schema].[table] VALUES (*)"
      assert_equal expected_sql, manager.to_sql
    end

    it 'should use fully qualified table name in update statement' do
      table = Arel::Table.new(:table)
      manager = Arel::UpdateManager.new(Arel::Table.engine)
      manager.table(table).where(table[:id].eq(42))
      manager.set([[table[:name], "Bob"]])
      expected_sql = "UPDATE [my.server].[db].[schema].[table] SET [name] = N'Bob' WHERE [table].[id] = 42"
      assert_equal expected_sql, manager.to_sql
    end

    it 'should use fully qualified table name in delete statement' do
      table = Arel::Table.new(:table)
      manager = Arel::DeleteManager.new(Arel::Table.engine)
      manager.from(table).where(table[:id].eq(42))
      expected_sql = "DELETE FROM [my.server].[db].[schema].[table] WHERE [table].[id] = 42"
      assert_equal expected_sql, manager.to_sql
    end

  end

end
