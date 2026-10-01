class DisplayLeaderboardService
  def self.call(game:, current_round:, current_question:)
    new(game:, current_round:, current_question:).execute
  end

  def initialize(game:, current_round:, current_question:)
    @game = game
    @current_round = current_round
    @current_question = current_question
  end

  def execute
    players = @game.players.order(score: :desc, username: :asc)

    broadcast_leaderboard(players)
    {
      players: players
    }
  end

  private

  def broadcast_leaderboard(players)
    ActionCable.server.broadcast(
      "game_room_#{@game.game_code}",
      {
        event: "display_leaderboard",
        round_id: @current_round.id,
        round_title: @current_round.title,

        players: players.map do |player|
          {
            id: player.id,
            username: player.username,
            score: player.score,
            eliminated: player.eliminated
          }
        end
      }
    )
  end
end
