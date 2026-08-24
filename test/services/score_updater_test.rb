require "test_helper"

class ScoreUpdaterTest < ActiveSupport::TestCase
  test "adds calculated points to the player" do
    game = games(:one)

    player = Player.create!(
      username: "Alice",
      score: 50,
      game: game
    )

    ScoreUpdater.call(
      player: player,
      correct: true,
      response_time_ms: 10_000
    )

    assert_equal 140, player.reload.score
  end

  test "does not change the player's score when the answer is incorrect" do
    game = games(:one)
    player = Player.create!(
      username: "Bob",
      score: 50,
      game: game
    )

    ScoreUpdater.call(
      player: player,
      correct: false,
      response_time_ms: 10_000
    )

    assert_equal 50, player.reload.score
  end

  test "adds points to a player with no points" do
    game = games(:one)
    player = Player.create!(
      username: "Charlie",
      score: 0,
      game: game
    )

    ScoreUpdater.call(
      player: player,
      correct: true,
      response_time_ms: 2_000
    )

    assert_equal 98, player.reload.score
  end
end
