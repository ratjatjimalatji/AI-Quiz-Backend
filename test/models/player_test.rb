require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  setup do
    @game = games(:one)
    @game.update!(status: "in_progress")
    @player = players(:one)
    @player.update!(
      score: 0,
      power_ups: Player::POWER_UPS.dup,
      active_power_up: nil,
      active_power_up_question_id: nil,
      eliminated: false
    )
    @question = questions(:one)
  end

  test "defines standard POWER_UPS list" do
    expected = %w[get_hundred_points double_points glitch_sabotage]
    assert_equal expected, Player::POWER_UPS
  end

  test "can_use_power_up? returns true when eligible" do
    assert @player.can_use_power_up?("get_hundred_points", @question)
    assert @player.can_use_power_up?("double_points", @question)
    assert @player.can_use_power_up?("glitch_sabotage", @question)
  end

  test "can_use_power_up? returns false when power-up is not in inventory" do
    @player.update!(power_ups: %w[double_points])
    assert_not @player.can_use_power_up?("get_hundred_points", @question)
  end

  test "can_use_power_up? returns false when question is already answered" do
    @player.submissions.create!(
      question: @question,
      round: @question.round,
      answer: "1",
      response_time_ms: 1000,
      points_awarded: 50
    )
    assert_not @player.can_use_power_up?("get_hundred_points", @question)
  end

  test "can_use_power_up? returns false when game is not in progress" do
    @game.update!(status: "waiting")
    assert_not @player.can_use_power_up?("get_hundred_points", @question)
  end

  test "activate_deferred_power_up! succeeds, deducts inventory, and records active power-up" do
    result = @player.activate_deferred_power_up!("double_points", @question)
    assert result

    @player.reload
    assert_equal "double_points", @player.active_power_up
    assert_equal @question.id, @player.active_power_up_question_id
    assert_not_includes @player.power_ups, "double_points"
  end

  test "activate_deferred_power_up! fails if another power-up is already active" do
    @player.activate_deferred_power_up!("double_points", @question)
    assert_not @player.activate_deferred_power_up!("double_points", @question)
  end

  test "consume_active_power_up! resets state and returns power-up name" do
    @player.activate_deferred_power_up!("double_points", @question)

    consumed = @player.consume_active_power_up!(@question)
    assert_equal "double_points", consumed

    @player.reload
    assert_nil @player.active_power_up
    assert_nil @player.active_power_up_question_id
  end

  test "consume_active_power_up! returns nil if question id does not match" do
    @player.activate_deferred_power_up!("double_points", @question)
    other_question = questions(:two)

    assert_nil @player.consume_active_power_up!(other_question)
    assert_equal "double_points", @player.active_power_up
  end
end
