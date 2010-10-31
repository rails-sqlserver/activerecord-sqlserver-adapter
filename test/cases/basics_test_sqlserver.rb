require 'cases/sqlserver_helper'
require 'models/developer'
require 'models/topic'

class BasicsTestSqlserver < ActiveRecord::TestCase
end

class BasicsTest < ActiveRecord::TestCase
  
  COERCED_TESTS = [
    :test_read_attributes_before_type_cast_on_datetime, 
    :test_preserving_date_objects,
    :test_to_xml ]
  
  include SqlserverCoercedTest
  
  fixtures :developers
  
  def test_coerced_test_read_attributes_before_type_cast_on_datetime
    developer = Developer.find(:first)
    if developer.created_at_before_type_cast.is_a?(String)
      assert_equal developer.created_at.to_s(:db)+'.000' , developer.attributes_before_type_cast["created_at"]
    end
  end
  
  def test_coerced_test_preserving_date_objects
    klass = sqlserver_2008? ? Date : (connection_mode_dblib? ? Time : Date)
    assert_kind_of klass, Topic.find(1).last_read, "The last_read attribute should be of the #{klass.name} class"
  end
  
  def test_coerced_test_to_xml
    xml = REXML::Document.new(topics(:first).to_xml(:indent => 0))
    bonus_time_in_current_timezone = topics(:first).bonus_time.xmlschema
    written_on_in_current_timezone = topics(:first).written_on.xmlschema
    
    assert_equal "topic", xml.root.name
    assert_equal "The First Topic" , xml.elements["//title"].text
    assert_equal "David" , xml.elements["//author-name"].text

    assert_equal "1", xml.elements["//id"].text
    assert_equal "integer" , xml.elements["//id"].attributes['type']

    assert_equal "1", xml.elements["//replies-count"].text
    assert_equal "integer" , xml.elements["//replies-count"].attributes['type']

    assert_equal written_on_in_current_timezone, xml.elements["//written-on"].text
    assert_equal "datetime" , xml.elements["//written-on"].attributes['type']

    assert_equal "--- Have a nice day\n" , xml.elements["//content"].text
    assert_equal "yaml" , xml.elements["//content"].attributes['type']

    assert_equal "david@loudthinking.com", xml.elements["//author-email-address"].text

    assert_equal nil, xml.elements["//parent-id"].text
    assert_equal "integer", xml.elements["//parent-id"].attributes['type']
    assert_equal "true", xml.elements["//parent-id"].attributes['nil']

    if sqlserver_2000? || sqlserver_2005?
      last_read_in_current_timezone, last_read_type = if connection_mode_odbc?
          ["2004-04-15", "date"]
        elsif connection_mode_dblib?
          ["2004-04-15 00:00:00", "date"]
        else
          [topics(:first).last_read.xmlschema, "datetime"]
        end
      assert_equal last_read_in_current_timezone, xml.elements["//last-read"].text
      assert_equal last_read_type , xml.elements["//last-read"].attributes['type']
    else
      assert_equal "2004-04-15", xml.elements["//last-read"].text
      assert_equal "date" , xml.elements["//last-read"].attributes['type']
    end

    assert_equal "false", xml.elements["//approved"].text
    assert_equal "boolean" , xml.elements["//approved"].attributes['type']

    assert_equal bonus_time_in_current_timezone, xml.elements["//bonus-time"].text
    assert_equal "datetime" , xml.elements["//bonus-time"].attributes['type']
  end
  
  
end
