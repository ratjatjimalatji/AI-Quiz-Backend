class RoundResultsService
  def self.call(game:, current_round:)
    new(game:, current_round:).execute
  end

  def initialize(game:, current_round:)
    @game = game
    @current_round = current_round
  end

  def execute
    advancing_players = PlayerAdvancementService.call(@game)

    eliminated_players = PlayerEliminationService.call(
      game: @game,
      advancing_players: advancing_players
    )

    remaining_players = @game.players.where(eliminated: false)

    winner = remaining_players.one? ? remaining_players.first : nil

    broadcast_results(
      advancing_players,
      eliminated_players,
      winner
    )
    {
      advancing: advancing_players,
      eliminated: eliminated_players,
      winner: winner
    }
  end

  private

  def broadcast_results(advancing_players, eliminated_players, winner)
    ActionCable.server.broadcast(
      "game_room_#{@game.game_code}",
      {
        event: "round_results",
        round_id: @current_round.id,
        round_title: @current_round.title,

        advancing_players: advancing_players.map do |player|
          {
            id: player.id,
            username: player.username,
            score: player.score
          }
        end,

        eliminated_players: eliminated_players.map do |player|
          {
            id: player.id,
            username: player.username,
            final_score: player.score
          }
        end,

        winner: winner && {
          id: winner.id,
          username: winner.username,
          score: winner.score
        }
      }
    )
  end
end
