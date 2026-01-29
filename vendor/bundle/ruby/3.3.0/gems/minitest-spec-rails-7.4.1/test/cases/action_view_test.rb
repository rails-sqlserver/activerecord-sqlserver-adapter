require 'test_helper'

class ActionViewTest < MiniTestSpecRails::TestCase
  it 'resolves spec type for matching helper strings' do
    assert_view Minitest::Spec.spec_type('WidgetHelper')
    assert_view Minitest::Spec.spec_type('WidgetHelperTest')
    assert_view Minitest::Spec.spec_type('Widget Helper Test')
    # And is case sensitive
    refute_view Minitest::Spec.spec_type('widgethelper')
    refute_view Minitest::Spec.spec_type('widgethelpertest')
    refute_view Minitest::Spec.spec_type('widget helper test')
  end

  it 'resolves spec type for matching view strings' do
    assert_view Minitest::Spec.spec_type('WidgetView')
    assert_view Minitest::Spec.spec_type('WidgetViewTest')
    assert_view Minitest::Spec.spec_type('Widget View Test')
    # And is case sensitive
    refute_view Minitest::Spec.spec_type('widgetview')
    refute_view Minitest::Spec.spec_type('widgetviewtest')
    refute_view Minitest::Spec.spec_type('widget view test')
  end

  it 'wont match spec type for non space characters' do
    refute_view Minitest::Spec.spec_type("Widget Helper\tTest")
    refute_view Minitest::Spec.spec_type("Widget Helper\rTest")
    refute_view Minitest::Spec.spec_type("Widget Helper\nTest")
    refute_view Minitest::Spec.spec_type("Widget Helper\fTest")
    refute_view Minitest::Spec.spec_type('Widget HelperXTest')
  end

  private

  def assert_view(actual)
    assert_equal ActionView::TestCase, actual
  end

  def refute_view(actual)
    refute_equal ActionView::TestCase, actual
  end
end
