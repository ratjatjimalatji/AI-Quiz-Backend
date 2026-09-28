class HostsController < ApplicationController
before_action :authenticate_host!, only: [ :create_game, :rejoin ]
  def index
      render json: Host.all
  end

  def create
      host = Host.create!(host_params)
      render json: { id: host.id, token: host.token }, status: :created
  end

  def create_game
    game = current_host.games.create!

       ActionCable.server.broadcast(
      "game_room_#{game.game_code}",
      {
        event: "game_created",
        game_code: game.game_code,
        total_players: game.players.count
      }
    )

     ActionCable.server.broadcast(
      "game_room_#{game.game_code}",
      {
        event: "host_joined",
        host: { id: current_host.id, name: current_host.name }
      }
     )

     render json: { id: game.id, code: game.game_code }, status: :created

  rescue ActiveRecord::RecordInvalid => e
  render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def rejoin
    game = current_host.games.find_by(game_code: params[:game_code])

    unless game
      return render json: { error: I18n.t("errors.game.not_found") }, status: :not_found
    end

    if game.completed?
      return render json: { error: I18n.t("errors.game.completed"), game_status: game.status }, status: :gone
    end

    render json: {
      success: true,
      host: { id: current_host.id, name: current_host.name },
      game: {
        id: game.id,
        game_code: game.game_code,
        status: game.status,
        current_round_id: game.current_round_id,
        players_count: game.players.count
      }
    }, status: :ok
  end


  private

  def host_params
    params.require(:host).permit(:name)
  end
end
