class QuestionsController < ApplicationController
  before_action :authenticate_host!, only: [ :create ]
  before_action :set_question, only: :update
  def index
    render json: Question.all.as_json(
      except: [ :correct_answer_ids ],
      include: :options
      )
  end

  def show
    question = Question.find(params[:id])
    render json: question.as_json(
      except: [ :correct_answer_ids ],
    include: :options
    )
  end

  def create
    question = Question.new(question_params)
    if question.save
      render json: question.as_json(
        except: [ :correct_answer_ids ],
        include: :options
      ),
       status: :created
    else
      render json: question.errors, status: :unprocessable_entity
    end
  end

  def update
    if @question.update(question_params)
      render json: @question.as_json(include: :options), status: :ok
    else
      render json: { errors: @question.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_question
    @question = Question.find(params[:id])
  end

  def question_params
    params.require(:question).permit(
      :title,
      :question_type,
      :round_id,
      :position,
      correct_answer_ids: [],
      options_attributes: [ :id, :text, :position, :_destroy ]
    )
  end
end
