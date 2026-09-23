# app/controllers/power_ups_controller.rb
class PowerUpsController < ApplicationController
  before_action :authenticate_player!

  def use
    question = Question.find(power_up_params[:question_id])
    power_name = power_up_params[:power_name]

    result = case power_name
    when "glitch_sabotage"
      PowerUps::GlitchSabotageService.call(
        initiator: current_player,
        question: question,
        victim_id: power_up_params[:victim_player_id]
      )

    when "get_hundred_points"
      PowerUps::AutoSubmit100Service.call(
        player: current_player,
        question: question
      )

    when "double_points"
      if current_player.activate_deferred_power_up!(power_name, question)
        { success: true, data: { active_power_up: power_name } }
      else
        { success: false, error: "Unable to activate power-up" }
      end

    else
      return render json: { success: false, error: "Invalid power-up: #{power_name}" }, status: :bad_request
    end

    if result[:success]
      render json: { success: true, power_name: power_name, data: result[:data] }, status: :ok
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def power_up_params
    params.require(:power_up).permit(:question_id, :power_name, :victim_player_id)
  end
end
