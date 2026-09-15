class QuestionsController < ApplicationController
  before_action :authenticate_host!, only: [ :create ]
  before_action :set_question, only: :update
  def index
    questions = Question.includes(:options).all
    render json: questions
  end

  def show
    question = Question.find(params[:id])
    render json: question
  end

  def create
    question = Question.new(question_params)
    if question.save
      render json: question, status: :created
    else
      render json: { errors: question.errors.full_messages }, status: :unprocessable_entity
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
      correct_option_position: [],
      options_attributes: [ :id, :text, :position, :_destroy ]
    )
  end
end
