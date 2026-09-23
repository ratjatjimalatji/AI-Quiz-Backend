require "test_helper"

module PowerUps
  class GlitchSabotageServiceTest < ActiveSupport::TestCase
    include ActionCable::TestHelper

    setup do
      @initiator = players(:one)
      @initiator.update!(
        score: 0,
        power_ups: %w[glitch_sabotage double_points],
        eliminated: false
      )
      @victim = players(:two)
      @victim.update!(
        score: 0,
        power_ups: %w[double_points],
        eliminated: false
      )
      @game = @initiator.game
      @victim.update!(game: @game)
      @question = questions(:one)
      @question.round.update!(game: @game)

      @game.update!(
        current_question_id: @question.id,
        question_started_at: 2.seconds.ago,
        status: "in_progress"
      )
    end

    test "successfully sabotages victim, deducts power-up, and broadcasts event" do
      result = nil

      assert_broadcast_on("game_room_#{@game.game_code}", {
        event: "#{@initiator.username} used glitch sabotaged on #{@victim.username}",
        initiator_id: @initiator.id,
        initiator_name: @initiator.username,
        victim_id: @victim.id,
        victim_name: @victim.username,
        question_id: @question.id,
        glitch_duration_ms: 10_000
      }) do
        result = GlitchSabotageService.call(
          initiator: @initiator,
          question: @question,
          victim_id: @victim.id
        )
      end

      assert_equal true, result[:success]
      assert_equal @victim.id, result[:data][:victim_player_id]
      assert_equal 10_000, result[:data][:glitch_duration_ms]

      @initiator.reload
      assert_not_includes @initiator.power_ups, "glitch_sabotage"
    end

    test "returns error when initiator does not have glitch_sabotage in inventory" do
      @initiator.update!(power_ups: %w[double_points])

      result = GlitchSabotageService.call(
        initiator: @initiator,
        question: @question,
        victim_id: @victim.id
      )

      assert_equal false, result[:success]
      assert_equal "Power-up not available", result[:error]
    end

    test "returns error when game is not in progress" do
      @game.update!(status: "waiting")

      result = GlitchSabotageService.call(
        initiator: @initiator,
        question: @question,
        victim_id: @victim.id
      )

      assert_equal false, result[:success]
      assert_equal "Game is not accepting submissions", result[:error]
    end

    test "returns error when victim is eliminated" do
      @victim.update!(eliminated: true)

      result = GlitchSabotageService.call(
        initiator: @initiator,
        question: @question,
        victim_id: @victim.id
      )

      assert_equal false, result[:success]
      assert_equal "Target player not found or eliminated", result[:error]
    end

    test "returns error when victim does not exist" do
      result = GlitchSabotageService.call(
        initiator: @initiator,
        question: @question,
        victim_id: -99999
      )

      assert_equal false, result[:success]
      assert_equal "Target player not found or eliminated", result[:error]
    end

    test "returns error when victim belongs to another game" do
      other_game = games(:two)
      @victim.update!(game: other_game)

      result = GlitchSabotageService.call(
        initiator: @initiator,
        question: @question,
        victim_id: @victim.id
      )

      assert_equal false, result[:success]
      assert_equal "Target player not found or eliminated", result[:error]
    end

    test "returns error when initiator attempts to sabotage themself" do
      result = GlitchSabotageService.call(
        initiator: @initiator,
        question: @question,
        victim_id: @initiator.id
      )

      assert_equal false, result[:success]
      assert_equal "Cannot sabotage yourself", result[:error]
    end
  end
end
