# frozen_string_literal: true

require "cases/helper_sqlserver"

class EnumTestSQLServer < ActiveRecord::TestCase

  # Check that enums are supported for all string types.
  # For each type we check: cast, serialize, and update by declaration.
  # We create a custom class for each type to test.
  %w[char_10 varchar_50 varchar_max text nchar_10 nvarchar_50 nvarchar_max ntext].each do |col_name|
    describe "support #{col_name} enums" do
      let(:klass) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'sst_datatypes'

          enum col_name => { alpha: "A", beta: "B" }
        end
      end

      it "type.cast" do
        type = klass.type_for_attribute(col_name)

        assert_equal "alpha",  type.cast('A')
        assert_equal "beta",   type.cast('B')
      end

      it "type.serialize" do
        type = klass.type_for_attribute(col_name)

        assert_equal 'A', type.serialize('A')
        assert_equal 'B', type.serialize('B')

        assert_equal 'A', type.serialize(:alpha)
        assert_equal 'B', type.serialize(:beta)
      end

      it "update by declaration" do
        r = klass.new

        r.alpha!
        assert_predicate r, :alpha?

        r.beta!
        assert_not_predicate r, :alpha?
        assert_predicate r, :beta?
      end
    end
  end
end
