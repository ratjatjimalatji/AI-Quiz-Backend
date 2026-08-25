require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "creates a game with valid attributes" do
    host = hosts(:one)
    game = Game.create!(
      player_limit: 8,
      host: host
    )

    assert game.persisted?
    assert game.game_code.present?
    assert_equal 8, game.player_limit
    assert_equal host, game.host
  end
end
