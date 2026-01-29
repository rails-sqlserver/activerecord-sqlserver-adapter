require 'test_helper_dummy'

module UsersHelperTests
  extend ActiveSupport::Concern
  included do
    let(:users_list) { render_users_list User.all }

    before { user_ken }

    it 'works' do
      user_ken
      expect(users_list).must_equal "<ul><li>#{user_ken.email}</li></ul>"
    end

    it 'can find the helper_class' do
      expect(self.class.helper_class).must_equal UsersHelper
    end

    describe 'nested 1' do
      it('works') { skip }

      it 'can find the helper_class' do
        expect(self.class.helper_class).must_equal UsersHelper
      end

      describe 'nested 2' do
        it('works') { skip }
      end
    end
  end
end

class UsersHelperTest < ActionView::TestCase
  include UsersHelperTests
  it 'reflects' do
    expect(described_class).must_equal UsersHelper
    expect(self.class.described_class).must_equal UsersHelper
  end
  describe 'level 1' do
    it 'reflects' do
      expect(described_class).must_equal UsersHelper
      expect(self.class.described_class).must_equal UsersHelper
    end
    describe 'level 2' do
      it 'reflects' do
        expect(described_class).must_equal UsersHelper
        expect(self.class.described_class).must_equal UsersHelper
      end
    end
  end
end

describe UsersHelper do
  include UsersHelperTests
  it 'reflects' do
    expect(described_class).must_equal UsersHelper
    expect(self.class.described_class).must_equal UsersHelper
  end
  describe 'level 1' do
    it 'reflects' do
      expect(described_class).must_equal UsersHelper
      expect(self.class.described_class).must_equal UsersHelper
    end
    describe 'level 2' do
      it 'reflects' do
        expect(described_class).must_equal UsersHelper
        expect(self.class.described_class).must_equal UsersHelper
      end
    end
  end
end
