class RoundTransitionService
  def self.call(game)
    new(game).process
  end

  def initialize(game)
    @game = game
    @round = game.current_round
  end

  def process
    # 1. Put the game into the summary state
    @game.update!(
      status: :round_summary,
      current_question: nil,
      question_started_at: nil
    )

    ActionCable.server.broadcast(
      "game_room_#{@game.game_code}",
      {
        event: "round_summary",
        game_id: @game.id,
        round_id: @round.id
      }
    )

    elimination_result = RoundResultsService.call(game: @game, current_round: @round)

  {
    advancing: elimination_result[:advancing],
    eliminated: elimination_result[:eliminated]
  }
  end
end
