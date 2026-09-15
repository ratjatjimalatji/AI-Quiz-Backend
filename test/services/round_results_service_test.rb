require "test_helper"

class RoundResultsServiceTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "returns advancing and eliminated players" do
    game = games(:one)
    round = rounds(:one)

    result = RoundResultsService.call(
      game: game,
      current_round: round
    )

    assert result.key?(:advancing)
    assert result.key?(:eliminated)
    assert result.key?(:winner)

    assert result[:advancing].all? { |player| player.is_a?(Player) }
    assert result[:eliminated].all? { |player| player.is_a?(Player) }
  end

  test "determines the winner when one active player remains" do
    game = games(:one)
    round = rounds(:one)

    player_one = players(:one)
    player_two = players(:two)

    player_one.update!(score: 200)
    player_two.update!(score: 100)

    result = RoundResultsService.call(
      game: game,
      current_round: round
    )

    assert_equal [ player_one ], result[:advancing]
    assert_equal [ player_two ], result[:eliminated]
    assert_equal player_one, result[:winner]

    assert_not player_one.reload.eliminated
    assert player_two.reload.eliminated
  end

  test "does not determine a winner when multiple active players remain" do
    game = games(:one)
    round = rounds(:one)

    player_one = players(:one)
    player_two = players(:two)

    player_two.update!(eliminated: true)

    result = RoundResultsService.call(
      game: game,
      current_round: round
    )

    assert_equal [ player_one ], result[:advancing]
    assert_empty result[:eliminated]
    assert_equal player_one, result[:winner]
  end

  test "broadcasts round results" do
    game = games(:one)
    round = rounds(:one)

    player_one = players(:one)
    player_two = players(:two)

    player_one.update!(score: 200)
    player_two.update!(score: 100)

    assert_broadcast_on(
      "game_room_#{game.game_code}",
      {
        event: "round_results",
        round_id: round.id,
        round_title: round.title,
        advancing_players: [
          {
            id: player_one.id,
            username: player_one.username,
            score: player_one.score
          }
        ],
        eliminated_players: [
          {
            id: player_two.id,
            username: player_two.username,
            final_score: player_two.score
          }
        ],
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

  test "returns no advancing or eliminated players when there are no active players" do
    game = games(:empty)
    round = rounds(:one)

    result = RoundResultsService.call(
      game: game,
      current_round: round
    )

    assert_empty result[:advancing]
    assert_empty result[:eliminated]
    assert_nil result[:winner]
  end
end
