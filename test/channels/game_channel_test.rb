require "test_helper"

class GameChannelTest < ActionCable::Channel::TestCase
  setup do
    @host = Host.create!(name: "Test Host")

    @game = @host.games.create!(
      game_code: "TEST123"
    )

    @player = @game.players.create!(
      username: "Alice"
    )
  end

  test "allows a player to subscribe to their game" do
    stub_connection(current_host: nil)

    subscribe(
      game_code: @game.game_code,
      player_id: @player.id
    )

    assert subscription.confirmed?
    assert_has_stream "game_room_#{@game.game_code}"
  end

  test "rejects a player who does not belong to the game" do
    stub_connection(current_host: nil)

    other_game = @host.games.create!(
      game_code: "OTHER123"
    )

    other_player = other_game.players.create!(
      username: "Bob"
    )

    subscribe(
      game_code: @game.game_code,
      player_id: other_player.id
    )

    assert subscription.rejected?
  end

  test "rejects subscription to an invalid game" do
    stub_connection(current_host: nil)

    subscribe(game_code: "INVALID_CODE")

    assert subscription.rejected?
  end
end
