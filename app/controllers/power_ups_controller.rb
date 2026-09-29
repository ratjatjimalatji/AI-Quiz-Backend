class PowerUpsController < ApplicationController
  before_action :authenticate_player!

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { success: false, error: e.message }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { success: false, error: e.message }, status: :bad_request
  end

  def use
    question   = Question.find(power_up_params[:question_id])
    power_name = power_up_params[:power_name]

    case power_name
    when "glitch_sabotage"   then use_glitch_sabotage(question, power_name)
    when "get_hundred_points" then use_get_hundred_points(question, power_name)
    when "double_points"     then use_double_points(question, power_name)
    else
      render_failure({ error: "Invalid power-up: #{power_name}" }, status: :bad_request)
    end
  end

  private

  def use_glitch_sabotage(question, power_name)
    result = PowerUps::GlitchSabotageService.call(
      initiator: current_player,
      question: question,
      victim_id: power_up_params[:victim_player_id]
    )
    return render_failure(result) unless result[:success]

    data = result[:data]
    render json: {
      success: true,
      status: "sabotage_sent",
      power_name: power_name,
      victim_id: data[:victim_player_id],
      data: data
    }, status: :ok
  end

  def use_get_hundred_points(question, power_name)
    result = PowerUps::AutoSubmit100Service.call(
      player: current_player,
      question: question
    )
    return render_failure(result) unless result[:success]

    data = result[:data]
    render json: {
      success: true,
      status: "auto_submitted",
      power_name: power_name,
      submission: data[:submission],
      points_awarded: data[:points_awarded],
      data: data
    }, status: :ok
  end

  def use_double_points(question, power_name)
    activated =
      begin
        current_player.activate_deferred_power_up!(power_name, question)
      rescue StandardError
        false
      end

    return render_failure({ error: "Unable to activate power-up" }) unless activated

    render json: {
      success: true,
      status: "activated",
      power_name: power_name,
      active_power_up: power_name,
      data: { active_power_up: power_name }
    }, status: :ok
  end

  def render_failure(result, status: :unprocessable_entity)
    render json: { success: false, error: result[:error] }, status: status
  end

  def power_up_params
    params.require(:power_up).permit(:question_id, :power_name, :victim_player_id)
  end
end
