require 'test_helper'

class NotificationMailer < ActionMailer::Base; end
class Notifications < ActionMailer::Base; end

class ActionMailerTest < MiniTestSpecRails::TestCase
  it 'matches spec type for class constants' do
    assert_mailer Minitest::Spec.spec_type(NotificationMailer)
    assert_mailer Minitest::Spec.spec_type(Notifications)
  end

  it 'matches spec type for strings' do
    assert_mailer Minitest::Spec.spec_type('WidgetMailer')
    assert_mailer Minitest::Spec.spec_type('WidgetMailerTest')
    assert_mailer Minitest::Spec.spec_type('Widget Mailer Test')
    # And is case sensitive
    refute_mailer Minitest::Spec.spec_type('widgetmailer')
    refute_mailer Minitest::Spec.spec_type('widgetmailertest')
    refute_mailer Minitest::Spec.spec_type('widget mailer test')
  end

  it 'wont match spec type for non space characters' do
    refute_mailer Minitest::Spec.spec_type("Widget Mailer\tTest")
    refute_mailer Minitest::Spec.spec_type("Widget Mailer\rTest")
    refute_mailer Minitest::Spec.spec_type("Widget Mailer\nTest")
    refute_mailer Minitest::Spec.spec_type("Widget Mailer\fTest")
    refute_mailer Minitest::Spec.spec_type('Widget MailerXTest')
  end

  private

  def assert_mailer(actual)
    assert_equal ActionMailer::TestCase, actual
  end

  def refute_mailer(actual)
    refute_equal ActionMailer::TestCase, actual
  end
end
