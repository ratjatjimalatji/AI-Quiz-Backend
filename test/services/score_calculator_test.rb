require "test_helper"

class ScoreUpdaterTest < ActiveSupport::TestCase
  test "adds the calculated points to the player's existing score" do
    game = games(:one)

    player = Player.create!(
      username: "Soulja Boy",
      score: 50,
      game: game
    )

    ScoreUpdater.call(
      player: player,
      correct: true,
      response_time_ms: 10_000
    )

    assert_equal 145, player.reload.score
  end

  test "does not change score when the answer is incorrect" do
    game = games(:one)

    player = Player.create!(
      username: "6LACK",
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

  test "adds the full 100 points when the answer is correct within the first 5 seconds" do
    game = games(:one)

    player = Player.create!(
      username: "CharlieXCX",
      score: 0,
      game: game
    )

    ScoreUpdater.call(
      player: player,
      correct: true,
      response_time_ms: 5_000
    )

    assert_equal 100, player.reload.score
  end

  test "adds 75 points when the player uses the full 30 seconds" do
    game = games(:one)

    player = Player.create!(
      username: "Desiigner",
      score: 0,
      game: game
    )

    ScoreUpdater.call(
      player: player,
      correct: true,
      response_time_ms: 30_000
    )

    assert_equal 75, player.reload.score
  end
end
