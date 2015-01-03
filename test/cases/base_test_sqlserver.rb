require 'cases/helper_sqlserver'
require 'models/post'
require 'models/auto_id'

class BasicsTest < ActiveRecord::TestCase

  include ARTest::Sqlserver::CoercedTest

  COERCED_TESTS = [
    :test_column_names_are_escaped
  ]

  it 'operates as other database adapters when finding primary keys, standard is postgresql adapter' do
    assert_nil Post.where(id:'').first
    assert_nil Post.where(id:nil).first
    assert_raise(ActiveRecord::RecordNotFound) { Post.find('') }
    assert_raise(ActiveRecord::RecordNotFound) { Post.find(nil) }
  end

  def test_coerced_column_names_are_escaped
    assert_equal "[foo]]bar]", ActiveRecord::Base.connection.quote_column_name("foo]bar")
  end

end
