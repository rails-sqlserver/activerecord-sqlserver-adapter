require 'test_helper'

class ModelsController < ApplicationController;  end

class ActionControllerTest < MiniTestSpecRails::TestCase
  it 'matches spec type for class constants' do
    assert_controller Minitest::Spec.spec_type(ApplicationController)
    assert_controller Minitest::Spec.spec_type(ModelsController)
  end

  it 'matches spec type for strings' do
    assert_controller Minitest::Spec.spec_type('WidgetController')
    assert_controller Minitest::Spec.spec_type('WidgetControllerTest')
    assert_controller Minitest::Spec.spec_type('Widget Controller Test')
    # And is case sensitive
    refute_controller Minitest::Spec.spec_type('widgetcontroller')
    refute_controller Minitest::Spec.spec_type('widgetcontrollertest')
    refute_controller Minitest::Spec.spec_type('widget controller test')
  end

  it 'wont match spec type for non space characters' do
    refute_controller Minitest::Spec.spec_type("Widget Controller\tTest")
    refute_controller Minitest::Spec.spec_type("Widget Controller\rTest")
    refute_controller Minitest::Spec.spec_type("Widget Controller\nTest")
    refute_controller Minitest::Spec.spec_type("Widget Controller\fTest")
    refute_controller Minitest::Spec.spec_type('Widget ControllerXTest')
  end

  private

  def assert_controller(actual)
    assert_equal ActionController::TestCase, actual
  end

  def refute_controller(actual)
    refute_equal ActionController::TestCase, actual
  end
end
