require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  setup do
    @host = Host.create!(
      name: "Test Host",
      token: "host-token"
    )

    @game = @host.games.create!(
      game_code: "TEST123"
    )

    @player = @game.players.create!(
      username: "Alice",
      token: "player-token"
    )
  end

  test "connects with a valid host token" do
    connect "/cable", params: { token: @host.token }

    assert_equal @host, connection.current_host
  end

  test "connects with a valid player token" do
    connect "/cable", params: { token: @player.token }

    assert_equal @player, connection.current_player
  end

  test "rejects an invalid token" do
    assert_reject_connection do
      connect "/cable", params: { token: "definitely-invalid-token" }
    end
  end

  test "rejects a connection without a token" do
    assert_reject_connection do
      connect "/cable"
    end
  end
end
