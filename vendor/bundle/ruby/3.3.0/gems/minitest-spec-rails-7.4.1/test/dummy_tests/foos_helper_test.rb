require 'test_helper_dummy'

class FoosHelperTest < ActionView::TestCase
  it 'allows path and url helpers' do
    expect(users_path_helper).must_equal '/users'
    expect(users_url_helper).must_equal  'http://test.host/users'
  end

  describe 'level1' do
    it 'works for helper method called in describe block' do
      assert passes
    end
  end
end
