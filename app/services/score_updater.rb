class ScoreUpdater
  def self.call(player:, correct:, response_time_ms:)
    new(
      player: player,
      correct: correct,
      response_time_ms: response_time_ms
    ).call
  end

  def initialize(player:, correct:, response_time_ms:)
    @player = player
    @correct = correct
    @response_time_ms = response_time_ms
  end

  def call
    return unless @correct
    points = ScoreCalculator.call(
      correct: @correct,
      response_time_ms: @response_time_ms
    )

    @player.increment!(:score, points)
  end
end
