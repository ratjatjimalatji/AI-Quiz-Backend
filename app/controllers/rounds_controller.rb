class RoundsController < ApplicationController
  def index
  render json: Round.all.as_json(
    include: {
      questions: {
        # except: [:correct_answer_ids],
        include: :options
      }
    }
  )
end

  def show
    round = Round.find(params[:id])
    render json: round.as_json(
  include: {
    questions: {
      # except: [:correct_answer_ids],
      include: :options
    }
  }
)
  end

  def create
    round = Round.new(round_params)

    if round.save
      render json: round.as_json(
  include: {
    questions: { #nested in round
      # except: [:correct_answer_ids], # dont show column
      include: :options
    }
  }
),
       status: :created
    else
      render json: round.errors, status: :unprocessable_entity
    end
  end

  private

  def round_params
    params.require(:round).permit(
      :title,
      :round_type,
      questions_attributes: [
        :id, :title, :question_type, :_destroy,
        {
        correct_answer_ids: [],
        options_attributes: [:id, :text, :position, :_destroy]
      }
      ]
    )
  end
end
