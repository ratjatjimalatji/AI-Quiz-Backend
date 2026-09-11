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

    GameChannel.broadcast_to(@game, {
      event: "round_summary"
    })

    elimination_result = PlayerEliminationService.call(@game, @round)

  {
    advancing: elimination_result[:advancing],
    eliminated: elimination_result[:eliminated]
  }
  end
end
