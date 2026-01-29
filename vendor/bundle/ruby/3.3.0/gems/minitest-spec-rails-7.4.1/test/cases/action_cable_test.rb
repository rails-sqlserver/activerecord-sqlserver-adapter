require 'test_helper'

class ModelsChannel < ApplicationCable::Channel;  end

class ActionCableChannelTest < MiniTestSpecRails::TestCase
  it 'matches spec type for class constants' do
    assert_channel_test Minitest::Spec.spec_type(ApplicationCable::Channel)
    assert_channel_test Minitest::Spec.spec_type(ModelsChannel)
  end

  it 'matches spec type for strings' do
    assert_channel_test Minitest::Spec.spec_type('WidgetChannel')
    assert_channel_test Minitest::Spec.spec_type('WidgetChannelTest')
    assert_channel_test Minitest::Spec.spec_type('Widget Channel Test')
    # And is case sensitive
    refute_channel_test Minitest::Spec.spec_type('widgetcontroller')
    refute_channel_test Minitest::Spec.spec_type('widgetcontrollertest')
    refute_channel_test Minitest::Spec.spec_type('widget controller test')
  end

  it 'wont match spec type for non space characters' do
    refute_channel_test Minitest::Spec.spec_type("Widget Channel\tTest")
    refute_channel_test Minitest::Spec.spec_type("Widget Channel\rTest")
    refute_channel_test Minitest::Spec.spec_type("Widget Channel\nTest")
    refute_channel_test Minitest::Spec.spec_type("Widget Channel\fTest")
    refute_channel_test Minitest::Spec.spec_type('Widget ChannelXTest')
  end

  private

  def assert_channel_test(actual)
    assert_equal ActionCable::Channel::TestCase, actual
  end

  def refute_channel_test(actual)
    refute_equal ActionCable::Channel::TestCase, actual
  end
end
