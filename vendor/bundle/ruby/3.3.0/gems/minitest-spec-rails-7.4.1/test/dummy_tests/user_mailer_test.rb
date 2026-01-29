require 'test_helper_dummy'

module UserMailerTests
  extend ActiveSupport::Concern
  included do
    let(:deliveries)        { ActionMailer::Base.deliveries }
    let(:user_mailer_class) { UserMailer }
    let(:user_email)        do
      user_mailer_class.welcome(user_ken).tap do |mail|
        mail.deliver_now
      end
    end

    it 'works' do
      expect(deliveries).must_be :empty?
      user_email
      expect(deliveries).wont_be :empty?
      expect(user_email.to).must_equal    [user_ken.email]
      expect(user_email.from).must_equal  ['rails@minitest.spec']
      expect(user_email.body.encoded).must_equal "Welcome to Minitest::Spec #{user_ken.email}!"
    end

    it 'allows custom assertions' do
      assert_emails(1) { user_email }
    end

    it 'can find the mailer_class' do
      expect(self.class.mailer_class).must_equal user_mailer_class
    end

    describe 'nested 1' do
      it('works') { skip }

      it 'can find the mailer_class' do
        expect(self.class.mailer_class).must_equal user_mailer_class
      end

      describe 'nested 2' do
        it('works') { skip }
      end
    end
  end
end

class UserMailerTest < ActionMailer::TestCase
  include UserMailerTests
  it 'reflects' do
    expect(described_class).must_equal UserMailer
    expect(self.class.described_class).must_equal UserMailer
  end
  describe 'level 1' do
    it 'reflects' do
      expect(described_class).must_equal UserMailer
      expect(self.class.described_class).must_equal UserMailer
    end
    describe 'level 2' do
      it 'reflects' do
        expect(described_class).must_equal UserMailer
        expect(self.class.described_class).must_equal UserMailer
      end
    end
  end
end

describe UserMailer do
  include UserMailerTests
  it 'reflects' do
    expect(described_class).must_equal UserMailer
    expect(self.class.described_class).must_equal UserMailer
  end
  describe 'level 1' do
    it 'reflects' do
      expect(described_class).must_equal UserMailer
      expect(self.class.described_class).must_equal UserMailer
    end
    describe 'level 2' do
      it 'reflects' do
        expect(described_class).must_equal UserMailer
        expect(self.class.described_class).must_equal UserMailer
      end
    end
  end
end
