class PlayersController < ApplicationController
  def index
    render json: Player.all
    
  end

  def show
    player = Player.find(params[:id])
  end

  def create
    player = Player.new(player_params)
  
    if player.save
      render json: player, status: :created
    else
      render json: player.errors, status: :unprocessable_entity
    end
  end

  private
    def player_params
      params.require(:player).permit(:username, :score, :eliminated, :game_id)
    end
  end 



