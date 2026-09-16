require "test_helper"

class PlayerAdvancementServiceTest < ActiveSupport::TestCase
  test "returns no advancing players when there are no active players" do
    game = games(:empty)

    result = PlayerAdvancementService.call(game)

    assert_empty result
  end

  test "advances the player with the highest score" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)

    result = PlayerAdvancementService.call(game)

    assert_equal [ player_one ], result
  end

  test "does not consider already eliminated players" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)

    player_two.update!(eliminated: true)

    result = PlayerAdvancementService.call(game)

    assert_equal [ player_one ], result
    assert_not player_one.reload.eliminated
    assert player_two.reload.eliminated
  end

  test "returns the player when only one active player remains" do
    game = games(:one)

    player_one = players(:one)
    players(:two).update!(eliminated: true)

    result = PlayerAdvancementService.call(game)

    assert_equal [ player_one ], result
  end

  test "returns players ordered by score" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)

    player_one.update!(score: 100)
    player_two.update!(score: 200)

    result = PlayerAdvancementService.call(game)

    assert_equal [ player_two ], result
  end
end
