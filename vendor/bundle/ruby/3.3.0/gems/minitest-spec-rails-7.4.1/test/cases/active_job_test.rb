require 'test_helper'

if defined?(ActiveJob)
  class MyJob < ActiveJob::Base
    def perform(_record)
      true
    end
  end
  class TrashableCleanupJob < MyJob
  end

  class ActiveJobTest < MiniTestSpecRails::TestCase
    it 'matches spec type for class constants' do
      assert_job Minitest::Spec.spec_type(MyJob)
      assert_job Minitest::Spec.spec_type(TrashableCleanupJob)
    end

    it 'matches spec type for strings' do
      assert_job Minitest::Spec.spec_type('WidgetJob')
      assert_job Minitest::Spec.spec_type('WidgetJobTest')
      assert_job Minitest::Spec.spec_type('Widget Job Test')
      # And is case sensitive
      refute_job Minitest::Spec.spec_type('widgetmailer')
      refute_job Minitest::Spec.spec_type('widgetmailertest')
      refute_job Minitest::Spec.spec_type('widget mailer test')
    end

    it 'wont match spec type for non space characters' do
      refute_job Minitest::Spec.spec_type("Widget Job\tTest")
      refute_job Minitest::Spec.spec_type("Widget Job\rTest")
      refute_job Minitest::Spec.spec_type("Widget Job\nTest")
      refute_job Minitest::Spec.spec_type("Widget Job\fTest")
      refute_job Minitest::Spec.spec_type('Widget JobXTest')
    end

    private

    def assert_job(actual)
      assert_equal ActiveJob::TestCase, actual
    end

    def refute_job(actual)
      refute_equal ActiveJob::TestCase, actual
    end
  end
end
