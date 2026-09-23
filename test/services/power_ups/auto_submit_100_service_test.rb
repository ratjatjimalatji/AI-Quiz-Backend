require "test_helper"

module PowerUps
  class AutoSubmit100ServiceTest < ActiveSupport::TestCase
    include ActionCable::TestHelper

    setup do
      @player = players(:one)
      @player.update!(
        score: 0,
        power_ups: %w[get_hundred_points double_points],
        eliminated: false,
        active_power_up: nil,
        active_power_up_question_id: nil
      )
      @game = @player.game
      @question = questions(:one)
      @question.round.update!(game: @game)

      @game.update!(
        current_question_id: @question.id,
        question_started_at: 4.seconds.ago,
        status: "in_progress"
      )
    end

    test "successfully submits, awards 100 points, and deducts inventory" do
      result = nil

      assert_difference -> { @player.submissions.count } => 1 do
        result = AutoSubmit100Service.call(
          player: @player,
          question: @question
        )
      end

      assert_equal true, result[:success]
      assert_equal 100, result[:data][:points_awarded]

      submission = result[:data][:submission]
      assert_equal @player.id, submission.player_id
      assert_equal @question.id, submission.question_id
      assert_equal "get_hundred_points", submission.answer
      assert_equal 100, submission.points_awarded

      @player.reload
      assert_equal 100, @player.score
      assert_not_includes @player.power_ups, "get_hundred_points"
    end

    test "broadcasts answer_submitted ActionCable event" do
      assert_broadcast_on("game_room_#{@game.game_code}", {
        event: "answer_submitted",
        player_id: @player.id,
        player_name: @player.username,
        question_id: @question.id,
        players_submitted: 1,
        total_players: @game.players.where(eliminated: false).count
      }) do
        AutoSubmit100Service.call(
          player: @player,
          question: @question
        )
      end
    end

    test "returns error when game is not in progress" do
      @game.update!(status: "waiting")

      assert_no_difference "Submission.count" do
        result = AutoSubmit100Service.call(
          player: @player,
          question: @question
        )

        assert_equal false, result[:success]
        assert_equal "Game is not accepting submissions", result[:error]
      end
    end

    test "returns error when player does not have power-up" do
      @player.update!(power_ups: %w[double_points])

      assert_no_difference "Submission.count" do
        result = AutoSubmit100Service.call(
          player: @player,
          question: @question
        )

        assert_equal false, result[:success]
        assert_equal "Power-up not available", result[:error]
      end
    end

    test "returns error when question was already answered" do
      @player.submissions.create!(
        question: @question,
        round: @question.round,
        answer: "1",
        response_time_ms: 1000,
        points_awarded: 50
      )

      assert_no_difference "Submission.count" do
        result = AutoSubmit100Service.call(
          player: @player,
          question: @question
        )

        assert_equal false, result[:success]
        assert_equal "Question already answered", result[:error]
      end
    end
  end
end
