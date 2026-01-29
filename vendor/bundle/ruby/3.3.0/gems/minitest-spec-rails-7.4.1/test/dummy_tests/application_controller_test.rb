require 'test_helper_dummy'

module ApplicationControllerTests
  extend ActiveSupport::Concern
  included do
    before { get :index }

    it 'works' do
      get :index
      expect(response.body).must_equal '<h1>Rendered Minitest::Spec</h1>'
    end

    it 'allows custom assertions' do
      assert_select 'h1', text: 'Rendered Minitest::Spec'
    end

    it 'can find the controller_class' do
      expect(self.class.controller_class).must_equal ApplicationController
    end

    it 'can access the setup ivars' do
      expect(@controller).must_be_kind_of ApplicationController
    end

    describe 'nested 1' do
      it('works') { skip }

      it 'can find the controller_class' do
        expect(self.class.controller_class).must_equal ApplicationController
      end

      describe 'nested 2' do
        it('works') { skip }
      end
    end
  end
end

class ApplicationControllerTest < ActionController::TestCase
  include ApplicationControllerTests
  it 'reflects' do
    expect(described_class).must_equal ApplicationController
    expect(self.class.described_class).must_equal ApplicationController
  end
  describe 'level 1' do
    it 'reflects' do
      expect(described_class).must_equal ApplicationController
      expect(self.class.described_class).must_equal ApplicationController
    end
    describe 'level 2' do
      it 'reflects' do
        expect(described_class).must_equal ApplicationController
        expect(self.class.described_class).must_equal ApplicationController
      end
    end
  end
end

describe ApplicationController do
  include ApplicationControllerTests
  it 'class reflects' do
    expect(described_class).must_equal ApplicationController
    expect(self.class.described_class).must_equal ApplicationController
  end
  it 'reflects' do
    expect(described_class).must_equal ApplicationController
    expect(self.class.described_class).must_equal ApplicationController
  end
  describe 'level 1' do
    it 'reflects' do
      expect(described_class).must_equal ApplicationController
      expect(self.class.described_class).must_equal ApplicationController
    end
    describe 'level 2' do
      it 'reflects' do
        expect(described_class).must_equal ApplicationController
        expect(self.class.described_class).must_equal ApplicationController
      end
    end
  end
end
