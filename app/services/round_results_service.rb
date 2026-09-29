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

    PlayerEliminationService.call(
      game: @game,
      advancing_players: advancing_players
    )

    remaining_players = @game.players.where(eliminated: false)

    winner = remaining_players.one? ? remaining_players.first : nil

    finalists = remaining_players.count == 2 ? remaining_players : []

    players = @game.players.order(score: :desc)

    broadcast_results(players, winner, finalists)
    {
      players: players,
      winner: winner,
      finalists: finalists
    }
  end

  private

  def broadcast_results(players, winner, finalists)
    ActionCable.server.broadcast(
      "game_room_#{@game.game_code}",
      {
        event: "round_results",
        round_id: @current_round.id,
        round_title: @current_round.title,

        players: players.map do |player|
          {
            id: player.id,
            username: player.username,
            score: player.score,
            eliminated: player.eliminated
          }
        end,

        winner: winner && {
          id: winner.id,
          username: winner.username,
          score: winner.score
        },
        finalists: finalists.map do |player|
          {
            id: player.id,
            username: player.username,
            score: player.score
          }
        end
      }
    )
  end
end
