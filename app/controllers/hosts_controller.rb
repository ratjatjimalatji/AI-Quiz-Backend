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
    game = current_host.games.create!(game_params)
    render json: { id: game.id, code: game.game_code }, status: :created
  end


    private

    def host_params
      params.require(:host).permit(:name)
    end
end
