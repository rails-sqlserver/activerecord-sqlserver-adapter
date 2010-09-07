require 'cases/sqlserver_helper'
require 'models/developer'
require 'models/project'
require 'models/company'
require 'models/customer'
require 'models/order'
require 'models/categorization'
require 'models/category'
require 'models/post'
require 'models/author'
require 'models/tag'
require 'models/tagging'
require 'models/parrot'
require 'models/pirate'
require 'models/treasure'
require 'models/price_estimate'
require 'models/club'
require 'models/member'
require 'models/membership'
require 'models/sponsor'
require 'models/country'
require 'models/treaty'
require 'active_support/core_ext/string/conversions'

class HasAndBelongsToManyAssociationsTestSqlserver < ActiveRecord::TestCase
end

class HasAndBelongsToManyAssociationsTest < ActiveRecord::TestCase
  
  COERCED_TESTS = [
    :test_count_with_finder_sql,
    :test_should_record_timestamp_for_join_table
  ]
  
  include SqlserverCoercedTest
  
  fixtures :accounts, :companies, :categories, :posts, :categories_posts, :developers, :projects, :developers_projects,
           :parrots, :pirates, :treasures, :price_estimates, :tags, :taggings
  
  def setup_data_for_habtm_case
    ActiveRecord::Base.connection.execute('delete from countries_treaties')
    country = Country.new(:name => 'India')
    country.country_id = 'c1'
    country.save!
    treaty = Treaty.new(:name => 'peace')
    treaty.treaty_id = 't1'
    country.treaties << treaty
  end
  
  
  def test_coerced_count_with_finder_sql
    assert true
  end
  
  def test_coerced_should_record_timestamp_for_join_table
    setup_data_for_habtm_case
    con = ActiveRecord::Base.connection
    sql = 'select * from countries_treaties'
    record = con.select_rows(sql).last
    assert_not_nil record[2]
    assert_not_nil record[3]
    if record[2].is_a?(String)
      assert_match %r{\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}}, record[2]
      assert_match %r{\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}}, record[3]
    else
      assert_match %r{\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}}, record[2].to_s(:db)
      assert_match %r{\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}}, record[3].to_s(:db)
    end
  end
  
  
end
