# app/services/power_ups/auto_submit100_service.rb
module PowerUps
  class AutoSubmit100Service
    def self.call(player:, question:)
      new(player: player, question: question).call
    end

    def initialize(player:, question:)
      @player = player
      @question = question
      @game = player.game
    end

    def call
      validate_get_hundred_points!

      submission = nil
      response_time_ms = ((Time.current - @game.question_started_at) * 1000).to_i

      used_power = (@player.power_ups & %w[get_hundred_points automatic_100_points]).first || "get_hundred_points"

      ActiveRecord::Base.transaction do
        # Deduct the power up from the inventory
        @player.power_ups = @player.power_ups - [ "get_hundred_points" ]
        @player.increment!(:score, 100)
        @player.save!

        # Create submission record bypass
        submission = @player.submissions.create!(
          question: @question,
          round: @question.round,
          answer: "get_hundred_points",
          response_time_ms: response_time_ms,
          points_awarded: 100
        )
      end

      broadcast_submission!

      {
      success: true,
      data: {
        submission: submission,
        points_awarded: 100 }
    }
    rescue StandardError => e
      { success: false, error: e.message }
    end

    private

    def validate_get_hundred_points!
      raise "Game is not accepting submissions" unless @game.status == "in_progress" # or your check: game.active_for_answers?
      raise "Power-up not available" unless (@player.power_ups & %w[get_hundred_points]).any?
      raise "Question already answered" if @player.submissions.exists?(question_id: @question.id)
    end

    def broadcast_submission!
      submission_count = Submission.where(question_id: @question.id).count
      ActionCable.server.broadcast(
        "game_room_#{@game.game_code}",
        {
          event: "answer_submitted",
          player_id: @player.id,
          player_name: @player.username,
          question_id: @question.id,
          players_submitted: submission_count,
          total_players: @game.players.where(eliminated: false).count
        }
      )
    end
  end
end
