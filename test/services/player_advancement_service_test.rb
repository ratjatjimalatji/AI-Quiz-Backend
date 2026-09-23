require "test_helper"

class PlayerAdvancementServiceTest < ActiveSupport::TestCase
  test "returns no advancing players when there are no active players" do
    game = games(:empty)

    result = PlayerAdvancementService.call(game)

    assert_empty result
  end

  test "advances half of the active players" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)
    player_three = players(:three)
    player_four = players(:four)

    player_one.update!(score: 400)
    player_two.update!(score: 300)
    player_three.update!(score: 200)
    player_four.update!(score: 100)

    result = PlayerAdvancementService.call(game)

    assert_equal [ player_one, player_two ], result
  end

  test "does not consider already eliminated players" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)
    player_three = players(:three)
    player_four = players(:four)

    player_one.update!(score: 400)
    player_two.update!(score: 300)
    player_three.update!(score: 200)
    player_four.update!(score: 100)

    player_two.update!(eliminated: true)

    result = PlayerAdvancementService.call(game)

    assert_equal [ player_one, player_three ], result

    assert_not player_one.reload.eliminated
    assert player_two.reload.eliminated
  end

  test "returns the player when only one active player remains" do
    game = games(:one)

    player_one = players(:one)

    players(:two).update!(eliminated: true)
    players(:three).update!(eliminated: true)
    players(:four).update!(eliminated: true)

    result = PlayerAdvancementService.call(game)

    assert_equal [ player_one ], result
  end

  test "advances the highest scoring half of the players" do
    game = games(:one)

    player_one = players(:one)
    player_two = players(:two)
    player_three = players(:three)
    player_four = players(:four)

    player_one.update!(score: 100)
    player_two.update!(score: 400)
    player_three.update!(score: 300)
    player_four.update!(score: 200)

    result = PlayerAdvancementService.call(game)

    assert_equal [ player_two, player_three ], result
  end
end
