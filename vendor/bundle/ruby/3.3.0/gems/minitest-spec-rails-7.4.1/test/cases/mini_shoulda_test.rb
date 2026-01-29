require 'test_helper_dummy'

class PostTests < ActiveSupport::TestCase
  i_suck_and_my_tests_are_order_dependent!

  $teardown_ran = false

  setup do
    @post = user_post
  end

  teardown do
    $teardown_ran = true
  end

  should 'setup correctly' do
    expect(@post).must_be_instance_of Post
  end

  should 'teardown correctly' do
    expect($teardown_ran).must_equal true
  end

  should_eventually 'will be skipped' do
    assert false
  end

  context 'level 1' do
    should 'work' do
      expect(@post).must_be_instance_of Post
    end
  end
end
