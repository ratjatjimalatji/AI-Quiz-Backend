class SubmissionsController < ApplicationController
  before_action :authenticate_player!

  def create
    question = Question.find(submission_params[:question_id])
    option = question.options.find(submission_params[:option_id])

    correct = question.correct_answer_ids.include?(option.id)

    points_awarded = ScoreUpdater.call(
      player: current_player,
      correct: correct,
      response_time_ms: submission_params[:response_time_ms].to_i
    )

    submission = current_player.submissions.create!(
      question: question,
      round: question.round,
      option: option,
      response_time_ms: submission_params[:response_time_ms],
      points_awarded: points_awarded
    )

    render json: submission, status: :created
  end

  private

  def submission_params
    params.require(:submission).permit(
      :question_id,
      :option_id,
      :response_time_ms
    )
  end
end
