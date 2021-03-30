# frozen_string_literal: true

require "cases/helper_sqlserver"
require "models/company"

class OptimizerHitsTestSQLServer < ActiveRecord::TestCase
  fixtures :companies

  it "apply optimizations" do
    assert_sql(%r{\ASELECT .+ FROM .+ OPTION \(HASH GROUP\)\z}) do
      companies = Company.optimizer_hints("HASH GROUP")
      companies = companies.distinct.select("firm_id")
      assert_includes companies.explain, "| Hash Match | Aggregate  |"
    end

    assert_sql(%r{\ASELECT .+ FROM .+ OPTION \(ORDER GROUP\)\z}) do
      companies = Company.optimizer_hints("ORDER GROUP")
      companies = companies.distinct.select("firm_id")
      assert_includes companies.explain, "| Stream Aggregate | Aggregate  |"
    end
  end

  it "sanitize values" do
    assert_sql(%r{\ASELECT .+ FROM .+ OPTION \(HASH GROUP\)\z}) do
      companies = Company.optimizer_hints("OPTION (HASH GROUP)")
      companies = companies.distinct.select("firm_id")
      companies.to_a
    end

    assert_sql(%r{\ASELECT .+ FROM .+ OPTION \(HASH GROUP\)\z}) do
      companies = Company.optimizer_hints("OPTION(HASH GROUP)")
      companies = companies.distinct.select("firm_id")
      companies.to_a
    end

    assert_sql(%r{\ASELECT .+ FROM .+ OPTION \(TABLE HINT \(\[companies\], INDEX\(1\)\)\)\z}) do
      companies = Company.optimizer_hints("OPTION(TABLE HINT ([companies], INDEX(1)))")
      companies = companies.distinct.select("firm_id")
      companies.to_a
    end
  end

  it "skip optimization after unscope" do
    assert_sql("SELECT DISTINCT [companies].[firm_id] FROM [companies]") do
      companies = Company.optimizer_hints("HASH GROUP")
      companies = companies.distinct.select("firm_id")
      companies.unscope(:optimizer_hints).load
    end
  end
end
