class SubmissionsController < ApplicationController
  before_action :authenticate_player!, only: [ :create ]

  def create
    question = Question.find(submission_params[:question_id])
    option = question.options.find(submission_params[:option_id])

    game = current_player.game

    response_time_ms =
      ((Time.current - game.question_started_at) * 1000).to_i

    correct = question.correct_answer_ids.include?(option.position)

    points_awarded = ScoreUpdater.call(
      player: current_player,
      correct: correct,
      response_time_ms: response_time_ms
    )

    submission = current_player.submissions.create!(
      question: question,
      round: question.round,
      option: option,
      response_time_ms: response_time_ms,
      points_awarded: points_awarded
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
      :option_id
    )
  end
end
