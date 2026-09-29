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
