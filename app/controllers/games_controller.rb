class GamesController < ApplicationController
 before_action :authenticate_host!, only: [ :create ]

    def index
    games = Game.all
    render json: games
    end

  def create
     game = current_host.games.create!(name: params[:name])

    render json: {
      id: game.id,
      code: game.code
    }, status: :created
  end

  private

  def game_params
    params.require(:game).permit(
      :game_code,
      :status,
      :host_id
    )
  end
end
