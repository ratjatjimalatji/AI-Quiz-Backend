class HostsController < ApplicationController
before_action :authenticate_host!, only: [ :create_game ]
  def index
      render json: Host.all
  end

  def create
      host = Host.create!(host_params)
      render json: { id: host.id, token: host.token }, status: :created
  end

  def create_game
  game = current_host.games.build

  if game.save
    ActionCable.server.broadcast(
      "game_room_#{game.game_code}",
      {
        event: "game_created",
        game_code: game.game_code,
        total_players: game.players.count,
        host: {
          id: current_host.id,
          name: current_host.name
        }
      }
    )

      render json: game, status: :created
  else
      render json: { errors: game.errors }, status: :unprocessable_entity
  end
  end


    private

    def host_params
      params.require(:host).permit(:name)
    end
end
