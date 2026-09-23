require "test_helper"

class RoundResultsServiceTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "returns players and winner" do
    game = games(:one)
    round = rounds(:one)

    result = RoundResultsService.call(
      game: game,
      current_round: round
    )

    assert result.key?(:players)
    assert result.key?(:winner)

    assert result[:players].all? { |player| player.is_a?(Player) }
  end

  test "determines the winner when one active player remains" do
  game = games(:one)
  round = rounds(:one)

  player_one = players(:one)
  player_two = players(:two)
  player_three = players(:three)
  player_four = players(:four)

  player_three.update!(eliminated: true)
  player_four.update!(eliminated: true)

  player_one.update!(score: 200)
  player_two.update!(score: 100)

  result = RoundResultsService.call(
    game: game,
    current_round: round
  )

  assert_equal [ player_one, player_two, player_three, player_four ], result[:players]

  assert_equal player_one, result[:winner]

  assert_not player_one.reload.eliminated
  assert player_two.reload.eliminated
end

 test "returns players sorted by score" do
  game = games(:one)
  round = rounds(:one)

  player_one = players(:one)
  player_two = players(:two)
  player_three = players(:three)
  player_four = players(:four)

  player_one.update!(score: 100)
  player_two.update!(score: 200)

  result = RoundResultsService.call(
    game: game,
    current_round: round
  )

  assert_equal(
    [ player_two, player_one, player_three, player_four ],
    result[:players]
  )
end

 test "broadcasts round results" do
  game = games(:one)
  round = rounds(:one)

  player_one = players(:one)
  player_two = players(:two)
  player_three = players(:three)
  player_four = players(:four)

  player_three.update!(eliminated: true)
  player_four.update!(eliminated: true)

  player_one.update!(score: 200)
  player_two.update!(score: 100)

  assert_broadcast_on(
    "game_room_#{game.game_code}",
    {
      event: "round_results",
      round_id: round.id,
      round_title: round.title,
      players: [
        {
          id: player_one.id,
          username: player_one.username,
          score: player_one.score,
          eliminated: false
        },
        {
          id: player_two.id,
          username: player_two.username,
          score: player_two.score,
          eliminated: true
        },
        {
          id: player_three.id,
          username: player_three.username,
          score: player_three.score,
          eliminated: true
        },
        {
          id: player_four.id,
          username: player_four.username,
          score: player_four.score,
          eliminated: true
        }
      ],
      finalists: [],
      winner: {
        id: player_one.id,
        username: player_one.username,
        score: player_one.score
      }
    }
  ) do
    RoundResultsService.call(
      game: game,
      current_round: round
    )
  end
end

  test "returns no players and no winner when there are no active players" do
    game = games(:empty)
    round = rounds(:one)

    result = RoundResultsService.call(
      game: game,
      current_round: round
    )

    assert_empty result[:players]
    assert_nil result[:winner]
  end

 test "broadcasts the finalists" do
  game = games(:one)
  round = rounds(:one)

  player_one = players(:one)
  player_two = players(:two)
  player_three = players(:three)
  player_four = players(:four)

  player_one.update!(score: 400)
  player_two.update!(score: 300)
  player_three.update!(score: 200)
  player_four.update!(score: 100)

  broadcasts = capture_broadcasts("game_room_#{game.game_code}") do
    RoundResultsService.call(
      game: game,
      current_round: round
    )
  end

  broadcast = broadcasts.first

  assert_equal(
    [
      {
        "id" => player_one.id,
        "username" => player_one.username,
        "score" => player_one.score
      },
      {
        "id" => player_two.id,
        "username" => player_two.username,
        "score" => player_two.score
      }
    ],
    broadcast["finalists"]
  )
end
end
