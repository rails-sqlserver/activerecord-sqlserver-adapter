require 'cases/sqlserver_helper'
require 'models/developer'
require 'models/topic'
require 'models_sqlserver/topic'

class AttributeMethodsTestSqlserver < ActiveRecord::TestCase
end

class AttributeMethodsTest < ActiveRecord::TestCase

  COERCED_TESTS = [
    :test_read_attributes_before_type_cast_on_datetime,
    :test_typecast_attribute_from_select_to_false,
    :test_typecast_attribute_from_select_to_true
  ]

  include SqlserverCoercedTest

  fixtures :developers

  def test_coerced_read_attributes_before_type_cast_on_datetime
    developer = Developer.first
    if developer.created_at_before_type_cast.is_a?(String)
      assert_equal "#{developer.created_at.to_s(:db)}.000" , developer.attributes_before_type_cast["created_at"]
    end
  end

  def test_coerced_typecast_attribute_from_select_to_false
    topic = Topic.create(title: 'Budget')
    topic = Topic.all.merge!(select: "topics.*, CASE WHEN 1=2 THEN 1 ELSE 0 END as is_test").first
    assert !topic.is_test?
  end

  def test_coerced_typecast_attribute_from_select_to_true
    topic = Topic.create(title: 'Budget')
    topic = Topic.all.merge!(select: "topics.*, CASE WHEN 2=2 THEN 1 ELSE 0 END as is_test").first
    assert topic.is_test?
  end


end
