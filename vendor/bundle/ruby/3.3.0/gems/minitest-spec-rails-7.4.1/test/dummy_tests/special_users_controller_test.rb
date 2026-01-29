require 'test_helper_dummy'

class SpecialUsersControllerTest < ActionController::TestCase
  tests UsersController

  it 'works' do
    get :index
    assert_select 'h1', "All #{User.count} Users"
  end
end
