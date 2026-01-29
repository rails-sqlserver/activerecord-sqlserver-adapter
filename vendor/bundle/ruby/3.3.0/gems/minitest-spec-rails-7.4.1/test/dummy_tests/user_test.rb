require 'test_helper_dummy'

module UserTests
  extend ActiveSupport::Concern
  included do
    it 'works' do
      expect(user_ken).must_be_instance_of User
    end

    test 'works with test' do
      expect(user_ken).must_be_instance_of User
    end

    it 'allows custom assertions' do
      assert_not false
    end

    describe 'nested 1' do
      it('works') { skip }

      describe 'nested 2' do
        it('works') { skip }
      end

      test 'works with test' do
        expect(user_ken).must_be_instance_of User
      end
    end
  end
end

class UserTest < ActiveSupport::TestCase
  include UserTests
  it 'reflects' do
    expect(described_class).must_equal User
    expect(self.class.described_class).must_equal User
  end
  describe 'level 1' do
    it 'reflects' do
      expect(described_class).must_equal User
      expect(self.class.described_class).must_equal User
    end
    describe 'level 2' do
      it 'reflects' do
        expect(described_class).must_equal User
        expect(self.class.described_class).must_equal User
      end
    end
  end
end

describe User do
  include UserTests
  it 'reflects' do
    expect(described_class).must_equal User
    expect(self.class.described_class).must_equal User
  end
  describe 'level 1' do
    it 'reflects' do
      expect(described_class).must_equal User
      expect(self.class.described_class).must_equal User
    end
    describe 'level 2' do
      it 'reflects' do
        expect(described_class).must_equal User
        expect(self.class.described_class).must_equal User
      end
    end
  end
end
