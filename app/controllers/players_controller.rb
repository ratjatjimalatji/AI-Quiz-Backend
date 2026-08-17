class PlayersController < ApplicationController
  def index
    render json: Player.all
  end

  def show
    player = Player.find(params[:id])
  end

  def create
    game = Game.find_by!(game_code: params[:game_code])

    if @game.players.count >= @game.player_limit
    render json: { error: "Game is full" }, status: :unprocessable_entity
    return
    end

     player = game.players.create!(
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
