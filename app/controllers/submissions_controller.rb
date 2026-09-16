class SubmissionsController < ApplicationController
  before_action :authenticate_player!

  def create
    question = Question.find(submission_params[:question_id])
    game = current_player.game

    response_time_ms =
      ((Time.current - game.question_started_at) * 1000).to_i

    correct = correct_answer?(question)

    points_awarded = ScoreUpdater.call(
      player: current_player,
      correct: correct,
      response_time_ms: response_time_ms
    )

    submission = current_player.submissions.create!(
      question: question,
      round: question.round,
      answer: submission_params[:answer],
      response_time_ms: response_time_ms,
      points_awarded: points_awarded
    )

    submission_count = Submission.where(question_id: question.id).count

    ActionCable.server.broadcast(
    "game_room_#{game.game_code}",
    {
      event: "answer_submitted",
      player_id: current_player.id,
      player_name: current_player.username,
      question_id: question.id,
      players_submitted: submission_count,
      total_players: game.players.where(eliminated: false).count
    }
  )

    render json: {
      submission: submission,
      correct: correct,
      points_awarded: points_awarded
    }, status: :created
  end

  private

  def submission_params
    params.require(:submission).permit(
      :question_id,
      :answer,
      answer: []
    )
  end

  def correct_answer?(question)
    case question.question_type
    when "true_false", "single_choice"
      question.correct_option_positions.include?(
        submission_params[:answer].to_i
      )

    when "drag_drop_order"
      submission_params[:answer].map(&:to_i) ==
        question.correct_option_positions

    when "type_the_answer"
      submitted_answer = submission_params[:answer].to_s.strip

      correct_answers = question.options.select { |opt| question.correct_option_positions.include?(opt.position) }.map(&:text)

      correct_answers.any? do |answer|
        answer.strip.casecmp?(submitted_answer)
      end

    else
      false
    end
  end
end
