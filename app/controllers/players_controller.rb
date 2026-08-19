class PlayersController < ApplicationController
  def index
    render json: Player.all
  end

  def show
    player = Player.find(params[:id])
  end

 def create
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
  def player_params
    params.require(:player).permit(:username)
  end
end
