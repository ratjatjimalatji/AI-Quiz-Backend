require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @host = Host.create!(name: "Host 1")
    @game = Game.create!(
      host: @host,
      status: "in_progress",
      player_limit: 10
    )
    @player = @game.players.create!(username: "Messi")
  end

  test "allows the player to rejoin the active game" do
    post rejoin_players_url,
         params: { game_code: @game.game_code },
         headers: {
           "Authorization" => "Bearer #{@player.token}"
         }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal true, json["success"]
    assert_equal "Messi", json["player"]["username"]
  end

  test "rejects rejoin when game has completed" do
    @game.update!(status: "completed")

    post rejoin_players_url,
         params: { game_code: @game.game_code },
         headers: {
           "Authorization" => "Bearer #{@player.token}"
         }

    assert_response :gone
  end

  test "rejects rejoin when token does not match any player in the game" do
    post rejoin_players_url,
         params: { game_code: @game.game_code },
         headers: {
           "Authorization" => "Bearer invalid_token_xyz"
         }

    assert_response :unauthorized
  end

  test "should get index" do
    get players_url
    assert_response :success
  end
  test "should create player" do
    game = games(:one)

    post create_player_games_url, params: {
      player: {
        username: "Test Player"
      },
      game_code: game.game_code
    }

    assert_response :created
  end
end
