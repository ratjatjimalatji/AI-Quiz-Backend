require "test_helper"

class PlayerEliminationServiceTest < ActiveSupport::TestCase
  test "returns no eliminated players when there are no active players" do
    game = games(:empty)

    result = PlayerEliminationService.call(
      game: game,
      advancing_players: []
    )

    assert_empty result
  end

  test "eliminates players who are not advancing" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)
    player_three = players(:three)
    player_four = players(:four)

    result = PlayerEliminationService.call(
      game: game,
      advancing_players: [ player_one, player_two ]
    )

    assert_equal [ player_three, player_four ], result

    assert_not player_one.reload.eliminated
    assert_not player_two.reload.eliminated
    assert player_three.reload.eliminated
    assert player_four.reload.eliminated
  end

  test "does not eliminate advancing players" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)
    player_three = players(:three)
    player_four = players(:four)

    PlayerEliminationService.call(
      game: game,
      advancing_players: [ player_one, player_two ]
    )

    assert_not player_one.reload.eliminated
    assert_not player_two.reload.eliminated
    assert player_three.reload.eliminated
    assert player_four.reload.eliminated
  end

  test "does not consider already eliminated players" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)
    player_three = players(:three)
    player_four = players(:four)

    player_three.update!(eliminated: true)

    result = PlayerEliminationService.call(
      game: game,
      advancing_players: [ player_one, player_two ]
    )

    assert_equal [ player_four ], result

    assert_not player_one.reload.eliminated
    assert_not player_two.reload.eliminated
    assert player_three.reload.eliminated
    assert player_four.reload.eliminated
  end

  test "returns eliminated players" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)
    player_three = players(:three)
    player_four = players(:four)

    result = PlayerEliminationService.call(
      game: game,
      advancing_players: [ player_one, player_two ]
    )

    assert result.all? { |player| player.is_a?(Player) }
    assert_equal [ player_three, player_four ], result
  end
end
