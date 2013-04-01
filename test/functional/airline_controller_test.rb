require 'test_helper'

class AirlineControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
