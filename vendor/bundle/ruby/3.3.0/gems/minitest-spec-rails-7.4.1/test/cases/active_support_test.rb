require 'test_helper'

class SomeRandomModel < ActiveRecord::Base; end

class ActiveSupportTest < MiniTestSpecRails::TestCase
  it 'resolves spec type for active record constants' do
    assert_support Minitest::Spec.spec_type(SomeRandomModel)
    assert_support Minitest::Spec.spec_type(User)
  end

  it 'wont resolve spec type for random strings' do
    assert_spec Minitest::Spec.spec_type('Unmatched String')
  end

  private

  def assert_support(actual)
    assert_equal ActiveSupport::TestCase, actual
  end

  def assert_spec(actual)
    assert_equal ActiveSupport::TestCase, actual
  end
end

class ActiveSupportCallbackTest < ActiveSupport::TestCase
  setup :foo
  setup :bar

  it 'works' do
    expect(@foo).must_equal 'foo'
    expect(@bar).must_equal 'bar'
  end

  private

  def foo
    @foo = 'foo'
  end

  def bar
    @bar = 'bar'
  end
end

class ActiveSupportSpecTest < ActiveSupport::TestCase
  it 'current spec name' do
    expect(Thread.current[:current_spec]).must_equal self
  end
end

class ActiveSupportDescribeNamesTest < ActiveSupport::TestCase
  it 'class name' do
    assert_equal 'ActiveSupportDescribeNamesTest', self.class.name
  end
  describe 'level1' do
    it 'haz name' do
      assert_equal 'ActiveSupportDescribeNamesTest::level1', self.class.name
    end
    describe 'level2' do
      it 'haz name' do
        assert_equal 'ActiveSupportDescribeNamesTest::level1::level2', self.class.name
      end
    end
  end
end

class ActiveSupportTestSyntaxTest < ActiveSupport::TestCase
  test 'records the correct test method line number' do
    method_name = public_methods(false).find do |name|
      name.to_s =~ /test.*records the correct test method line number/
    end
    method_obj = method(method_name)

    assert_match %r{test\/cases\/active_support_test.rb}, method_obj.source_location[0]
    assert_equal 69, method_obj.source_location[1]
  end
end
