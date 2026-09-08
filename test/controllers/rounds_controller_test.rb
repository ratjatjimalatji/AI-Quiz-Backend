require "test_helper"

class RoundsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get rounds_url
    assert_response :success
  end
 test "should create round" do
  game = games(:one)

  post rounds_url, params: {
    round: {
      title: "Test Round",
      game_id: game.id
    }
  }

  assert_response :created
end

  test "should get show" do
    get round_url(rounds(:one))
    assert_response :success
  end
end
