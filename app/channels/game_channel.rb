class GameChannel < ApplicationCable::Channel
  def subscribed
    @game = Game.find_by(game_code: params[:game_code])

    return reject unless @game

    if connection.current_player
      return reject unless player_authorized?(@game)
    elsif connection.current_host
      return reject unless host_authorized?(@game)
    else
      return reject
    end

    stream_from "game_room_#{@game.game_code}"
  end

  def unsubscribed
    stop_all_streams
    logger.info "Client unsubscribed from game room: #{@game.game_code}" if @game
  end

  def submit_answer(data)
    player = @game.players.find_by(id: data["player_id"])
    return unless player

    ActionCable.server.broadcast(
      "game_room_#{@game.game_code}",
      {
        event: "answer_submitted",
        player_id: player.id,
        status: "waiting_for_results"
      }
    )
  end

  private

  def host_authorized?(game)
    connection.current_host&.id == game.host_id
  end

  def player_authorized?(game)
    game.players.exists?(id: connection.current_player&.id)
  end
end
