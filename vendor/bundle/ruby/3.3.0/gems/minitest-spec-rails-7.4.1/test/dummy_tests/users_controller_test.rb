require 'test_helper_dummy'

module UsersControllerTests
  extend ActiveSupport::Concern
  included do
    it 'works' do
      get :index
      assert_select 'h1', "All #{User.count} Users"
    end

    it 'redirects' do
      put_update_0
      assert_redirected_to users_url
    end

    private

    def put_update_0
      put :update, params: { id: 0 }
    end
  end
end

class UsersControllerTest < ActionController::TestCase
  include UsersControllerTests
end

describe UsersController do
  include UsersControllerTests
end
