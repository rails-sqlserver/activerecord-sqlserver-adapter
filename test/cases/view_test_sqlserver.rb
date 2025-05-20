# frozen_string_literal: true

require "cases/helper_sqlserver"

class ViewTestSQLServer < ActiveRecord::TestCase
  let(:connection) { ActiveRecord::Base.lease_connection }

  describe 'view with default values' do
    before do
      connection.drop_table :view_casing_table rescue nil
      connection.create_table :view_casing_table, force: true do |t|
        t.boolean :Default_Falsey,      null: false, default: false
        t.boolean :Default_Truthy,      null: false, default: true
        t.string  :default_string_null, null: true,  default: nil
        t.string  :default_string,      null: false, default: "abc"
      end

      connection.execute("DROP VIEW IF EXISTS view_casing_table_view;")
      connection.execute <<-SQL
        CREATE VIEW view_casing_table_view AS
              SELECT id AS id,
                     default_falsey      AS falsey,
                     default_truthy      AS truthy,
                     default_string_null AS s_null,
                     default_string      AS s
              FROM view_casing_table
      SQL
    end

    it "default values are correct when column casing used in tables and views are different" do
      klass = Class.new(ActiveRecord::Base) do
        self.table_name = "view_casing_table_view"
      end

      obj = klass.new
      assert_equal false, obj.falsey
      assert_equal true, obj.truthy
      assert_equal "abc", obj.s
      assert_nil   obj.s_null
      assert_equal 0, klass.count

      obj.save!
      assert_equal false, obj.falsey
      assert_equal true, obj.truthy
      assert_equal "abc", obj.s
      assert_nil   obj.s_null
      assert_equal 1, klass.count
    end
  end

  describe "identity insert" do
    it "creates table record through a view" do
      assert_difference("SSTestCustomersView.count", 2) do
        SSTestCustomersView.create!(id: 5, name: "Bob")
        SSTestCustomersView.create!(id: 6, name: "Tim")
      end
    end

    it "creates table records through a view using fixtures" do
      ActiveRecord::FixtureSet.create_fixtures(File.join(ARTest::SQLServer.test_root_sqlserver, "fixtures"), ["sst_customers_view"])
      assert_equal SSTestCustomersView.all.count, 2
    end
  end
end
