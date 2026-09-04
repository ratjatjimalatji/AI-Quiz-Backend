class GamesController < ApplicationController
    def index
    games = Game.all
    render json: games
    end
  def create_player
    game_code = params[:game_code]

    if game_code.blank?
      render json: { error: "game_code is required" }, status: :bad_request
      return
    end

    game = Game.find_by(game_code: game_code)

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

       ActionCable.server.broadcast(
      "game_room_#{game.game_code}",
      {
        event: "player_joined",
        player: { id: player.id, username: player.username },
        total_players: game.players.count,
        player_limit: game.player_limit
      }
    )
      render json: player, status: :created
    else
      render json: player.errors, status: :unprocessable_entity
    end
  end

  def get_players
  game = Game.find_by!(game_code: params[:game_code])

  render json: game.players.select(:id, :username)
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
