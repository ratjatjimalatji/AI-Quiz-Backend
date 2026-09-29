class PlayersController < ApplicationController
before_action :authenticate_player!, only: [ :rejoin ]
  def index
    render json: Player.all
  end

  def show
    player = Player.find(params[:id])
  end

  def rejoin
    game_code = params[:game_code]
    token = request.headers[Networking::Headers::AUTHORIZATION]&.split(" ")&.last || params[:token]

    game = Game.find_by(game_code: game_code)
    return render json: { error: I18n.t("errors.game.not_found") }, status: :not_found unless game

    if game.status == "completed" || game.status == "cancelled"
      return render json: { error: I18n.t("errors.game.no_longer_active"), game_status: game.status }, status: :gone
    end

    player = game.players.find_by(token: token)
    return render json: { error: I18n.t("errors.player.invalid_session_token") }, status: :unauthorized unless player

    render json: {
      success: true,
      player:  {
        id: player.id,
        username: player.username,
        score: player.score,
        eliminated: player.eliminated
      },
      game: {
        id: game.id,
        game_code: game.game_code,
        status: game.status,
        current_round_id: game.current_round_id,
        current_question_id: game.current_question_id
      }
    }, status: :ok
  end

 private
  def player_params
    params.require(:player).permit(:username)
  end
end
