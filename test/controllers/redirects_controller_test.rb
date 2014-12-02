require 'test_helper'

class RedirectsControllerTest < ActionController::TestCase
  test "should get status" do
    get :status
    assert_response :success
  end

end
