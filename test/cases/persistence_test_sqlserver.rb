require 'cases/sqlserver_helper'
require 'models/post'
require 'models/comment'
require 'models/author'
require 'models/topic'
require 'models/reply'
require 'models/category'
require 'models/company'
require 'models/developer'
require 'models/project'
require 'models/minimalistic'
require 'models/warehouse_thing'
require 'models/parrot'
require 'models/minivan'
require 'models/person'
require 'rexml/document'

class PersistencesTestSqlserver < ActiveRecord::TestCase
end

class PersistencesTest < ActiveRecord::TestCase
  
  fixtures :topics, :companies, :developers, :projects, :computers, :accounts, :minimalistics, 'warehouse-things', :authors, :categorizations, :categories, :posts, :minivans
  
  COERCED_TESTS = [:test_update_all_doesnt_ignore_order]
  
  include SqlserverCoercedTest
  
  def test_coerced_update_all_doesnt_ignore_order
    assert_equal authors(:david).id + 1, authors(:mary).id
    test_update_with_order_succeeds = lambda do |order|
      begin
        Author.order(order).update_all('id = id + 1')
      rescue ActiveRecord::ActiveRecordError
        false
      end
    end
    if test_update_with_order_succeeds.call('id DESC')
      assert !test_update_with_order_succeeds.call('id ASC')
    else
      assert_sql(/UPDATE .* \(SELECT .* ORDER BY id DESC\)/i) do
        test_update_with_order_succeeds.call('id DESC')
      end
    end
  end
  
end


