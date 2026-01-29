require 'dummy_app/init'
require 'support/shared_test_case_behavior'

module MiniTestSpecRails
  class TestCase < Minitest::Spec
    include MiniTestSpecRails::SharedTestCaseBehavior
  end
end
