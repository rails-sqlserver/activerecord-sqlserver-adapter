require 'test_helper'

module ActiveSupport
  class TestCase
    fixtures :all
    include MiniTestSpecRails::SharedTestCaseBehavior
  end
end
