# app/controllers/power_ups_controller.rb
class PowerUpsController < ApplicationController
  before_action :authenticate_player!

  def use
    question = Question.find(power_up_params[:question_id])
    power_name = power_up_params[:power_name]

    case power_name
    when "glitch_sabotage"
      result = PowerUps::GlitchSabotageService.call(
        initiator: current_player,
        question: question,
        victim_id: power_up_params[:target_player_id]
      )

      if result[:success]
        render json: { status: "sabotage_sent", target_player_id: result[:target_player].id }, status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end

    when "automatic_100_points"
      result = PowerUps::AutoSubmit100Service.call(
        player: current_player,
        question: question
      )

      if result[:success]
        render json: {
          status: "auto_submitted",
          submission: result[:submission],
          points_awarded: result[:points_awarded]
        }, status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end

    when "double_points"
      if current_player.activate_deferred_power_up!(power_name, question)
        render json: { status: "activated", active_power_up: power_name }, status: :ok
      else
        render json: { error: "Unable to activate power-up" }, status: :unprocessable_entity
      end

    else
      render json: { error: "Invalid power-up" }, status: :bad_request
    end
  end

  private

  def power_up_params
    params.require(:power_up).permit(:question_id, :power_name, :target_player_id)
  end
end
