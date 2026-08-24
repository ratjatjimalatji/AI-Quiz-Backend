class GamesController < ApplicationController
 before_action :authenticate_host!, only: [ :create ]

    def index
    games = Game.all
    render json: games
    end

  def create
    game = current_host.games.create!(game_params)
    render json: { id: game.id, code: game.code }, status: :created
  end

  def create_player
    game = Game.find_by!(game_code: params[:game_code])

    if game.players.count >= game.player_limit
      render json: {
        error: I18n.t(
          "activerecord.errors.models.game.attributes.player_limit.limit_exceeded"
        )
      }, status: :unprocessable_entity
      return
    end

    player = game.players.build(
      username: player_params[:username]
    )

    if player.save
      render json: player, status: :created
    else
      render json: player.errors, status: :unprocessable_entity
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

  def player_params
    params.require(:player).permit(:username)
  end
end
