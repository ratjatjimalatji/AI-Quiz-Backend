class GamesController < ApplicationController

    def index
    games = Game.all

    render json: games
  end

  def create
    game = Game.new(game_params)

    if game.save
         host = game.players.create!(
      username: params[:host_username],
      is_host: true,
      score: 0,
      eliminated: false
    )
      render json: game, status: :created
    else
      render json: { errors: game.errors },
             status: :unprocessable_entity
    end
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
