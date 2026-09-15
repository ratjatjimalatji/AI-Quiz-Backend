require "test_helper"

class PlayerEliminationServiceTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  test "returns no advancing or eliminated players when there are no active players" do
  game = games(:empty)
  round = rounds(:one)

  result = PlayerEliminationService.call(game, round)

  assert_empty result[:advancing]
  assert_empty result[:eliminated]
  end

  test "advances the player with the highest score" do
    game = games(:one)
    round = rounds(:one)

    player_one = players(:one)
    player_two = players(:two)

    result = PlayerEliminationService.call(game, round)

    assert_equal [ player_one ], result[:advancing]
    assert_equal [ player_two ], result[:eliminated]
  end

  test "eliminates players with lower scores" do
    game = games(:one)
    round = rounds(:one)

    player_one = players(:one)
    player_two = players(:two)

    PlayerEliminationService.call(game, round)

    assert_not player_one.reload.eliminated
    assert player_two.reload.eliminated
  end

  test "does not consider already eliminated players" do
    game = games(:one)
    round = rounds(:one)

    player_one = players(:one)
    player_two = players(:two)

    player_two.update!(eliminated: true)

    result = PlayerEliminationService.call(game, round)

    assert_equal [ player_one ], result[:advancing]
    assert_empty result[:eliminated]

    assert_not player_one.reload.eliminated
    assert player_two.reload.eliminated
  end

  test "returns advancing and eliminated players" do
    game = games(:one)
    round = rounds(:one)

    result = PlayerEliminationService.call(game, round)

    assert result.key?(:advancing)
    assert result.key?(:eliminated)

    assert result[:advancing].all? { |player| player.is_a?(Player) }
    assert result[:eliminated].all? { |player| player.is_a?(Player) }
  end
  test "broadcasts elimination results" do
  game = games(:one)
  round = rounds(:one)

  player_one = players(:one)
  player_two = players(:two)

  assert_broadcast_on(
    "game_room_#{game.game_code}",
    {
      event: "players_eliminated",
      round_id: round.id,
      round_title: round.title,
      advancing_player_ids: [
        id: player_one.id,
        username: player_one.username,
        score: player_one.score
      ],
      eliminated_players: [
        {
          id: player_two.id,
          username: player_two.username,
          final_score: player_two.score
        }
      ]
    }
  ) do
    PlayerEliminationService.call(game, round)
  end
  end
end
