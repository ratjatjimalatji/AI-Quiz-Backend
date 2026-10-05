class RoundTransitionService
  def self.call(game)
    new(game).process
  end

  def initialize(game)
    @game = game
    @round = game.current_round
  end

  def process
    result = nil

    ActiveRecord::Base.transaction do
    @game.update!(
      status: :round_summary,
      current_question: nil,
      question_started_at: nil
    )

    result = RoundResultsService.call(game: @game, current_round: @round)

    @game.players.reload.where(eliminated: false).update_all(
        power_ups: Player::POWER_UPS.dup,
        active_power_up: nil,
        active_power_up_question_id: nil
      )
    end

    ActionCable.server.broadcast(
      "game_room_#{@game.game_code}",
      {
        event: "round_summary",
        game_id: @game.id,
        round_id: @round.id
      }
    )

  {
    advancing: result[:advancing],
    eliminated: result[:eliminated]
  }
  end
end
