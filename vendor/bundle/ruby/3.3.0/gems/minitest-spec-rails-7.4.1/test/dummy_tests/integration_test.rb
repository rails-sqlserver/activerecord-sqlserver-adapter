require 'test_helper_dummy'

module IntegrationTests
  extend ActiveSupport::Concern
  included do
    fixtures :all

    it 'works' do
      get root_path
      expect(status).must_equal 200
    end

    it 'works with assert_routing' do
      assert_routing '/', controller: 'application', action: 'index'
    end

    it 'can find the app' do
      expect(app).must_be_instance_of Dummy::Application
    end

    describe 'nested 1' do
      it('works') { skip }

      it 'can find the app' do
        expect(app).must_be_instance_of Dummy::Application
      end

      describe 'nested 2' do
        it('works') { skip }
      end
    end
  end
end

class IntegrationTest < ActionDispatch::IntegrationTest
  include IntegrationTests
end

class AppTest < ActionDispatch::IntegrationTest
  def test_homepage
    assert_routing '/', controller: 'application', action: 'index'
  end
end
