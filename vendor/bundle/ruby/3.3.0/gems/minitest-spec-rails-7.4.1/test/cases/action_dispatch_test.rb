require 'test_helper'

class ModelsController < ApplicationController;  end

class ActionControllerTest < MiniTestSpecRails::TestCase
  it 'resolves spec type for matching acceptance strings' do
    assert_dispatch Minitest::Spec.spec_type('WidgetAcceptanceTest')
    assert_dispatch Minitest::Spec.spec_type('Widget Acceptance Test')
    # And is case sensitive
    refute_dispatch Minitest::Spec.spec_type('widgetacceptancetest')
    refute_dispatch Minitest::Spec.spec_type('widget acceptance test')
  end

  it 'wont match spec type for space characters in acceptance strings' do
    refute_dispatch Minitest::Spec.spec_type("Widget Acceptance\tTest")
    refute_dispatch Minitest::Spec.spec_type("Widget Acceptance\rTest")
    refute_dispatch Minitest::Spec.spec_type("Widget Acceptance\nTest")
    refute_dispatch Minitest::Spec.spec_type("Widget Acceptance\fTest")
    refute_dispatch Minitest::Spec.spec_type('Widget AcceptanceXTest')
  end

  it 'resolves spec type for matching integration strings' do
    assert_dispatch Minitest::Spec.spec_type('WidgetIntegrationTest')
    assert_dispatch Minitest::Spec.spec_type('Widget Integration Test')
    # And is case sensitive
    refute_dispatch Minitest::Spec.spec_type('widgetintegrationtest')
    refute_dispatch Minitest::Spec.spec_type('widget integration test')
  end

  it 'wont match spec type for space characters in integration strings' do
    refute_dispatch Minitest::Spec.spec_type("Widget Integration\tTest")
    refute_dispatch Minitest::Spec.spec_type("Widget Integration\rTest")
    refute_dispatch Minitest::Spec.spec_type("Widget Integration\nTest")
    refute_dispatch Minitest::Spec.spec_type("Widget Integration\fTest")
    refute_dispatch Minitest::Spec.spec_type('Widget IntegrationXTest')
  end

  private

  def assert_dispatch(actual)
    assert_equal ActionDispatch::IntegrationTest, actual
  end

  def refute_dispatch(actual)
    refute_equal ActionDispatch::IntegrationTest, actual
  end
end
