require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should get new" do
    get :new
    assert_response :success
  end

#  test "should get status" do
#    get :status
#    assert_response :success
#  end

end
