class RoundsController < ApplicationController
  def index
    rounds = Round.includes(questions: :options).all
    render json: rounds
  end

  def show
    round = Round.find(params[:id])
    render json: round
  end

  def create
    round = Round.new(round_params)

    if round.save
      render json: round, status: :created
    else
      render json: { errors: round.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def round_params
    params.require(:round).permit(
      :title,
      :round_type,
      :game_id,
      questions_attributes: [
        :id,
        :title,
        :question_type,
        :_destroy,
        {
        correct_answer_ids: [],
        options_attributes: [ :id, :text, :position, :_destroy ]
      }
      ]
    )
  end
end
