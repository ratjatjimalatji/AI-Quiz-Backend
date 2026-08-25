require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get players_url
    assert_response :success
  end

  test "should create player" do
    game = games(:one)

    post create_player_game_url(game.id), params: {
      player: {
        username: "Test Player"
      },
      game_code: game.game_code
    }

    assert_response :created
  end
end
