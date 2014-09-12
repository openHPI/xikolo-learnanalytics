require 'test_helper'

class TrackingControllerTest < ActionController::TestCase
  test "should get track" do
    get :track
    assert_response :success
  end

  test "should get bulk_track" do
    get :bulk_track
    assert_response :success
  end

end
