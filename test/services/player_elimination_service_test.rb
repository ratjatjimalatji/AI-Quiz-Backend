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

    result = PlayerEliminationService.call(
      game: game,
      advancing_players: [ player_one ]
    )

    assert_equal [ player_two ], result

    assert_not player_one.reload.eliminated
    assert player_two.reload.eliminated
  end

  test "does not eliminate advancing players" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)

    PlayerEliminationService.call(
      game: game,
      advancing_players: [ player_one ]
    )

    assert_not player_one.reload.eliminated
    assert player_two.reload.eliminated
  end

  test "does not consider already eliminated players" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)

    player_two.update!(eliminated: true)

    result = PlayerEliminationService.call(
      game: game,
      advancing_players: [ player_one ]
    )

    assert_empty result
    assert_not player_one.reload.eliminated
    assert player_two.reload.eliminated
  end

  test "returns eliminated players" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)

    result = PlayerEliminationService.call(
      game: game,
      advancing_players: [ player_one ]
    )

    assert result.all? { |player| player.is_a?(Player) }
    assert_equal [ player_two ], result
  end
end
