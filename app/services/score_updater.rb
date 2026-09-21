class ScoreUpdater
  def self.call(player:, correct:, response_time_ms:, power_up_name: nil)
    new(
      player: player,
      correct: correct,
      response_time_ms: response_time_ms,
      power_up_name: power_up_name
    ).call
  end

  def initialize(player:, correct:, response_time_ms:, power_up_name: nil)
    @player = player
    @correct = correct
    @response_time_ms = response_time_ms
    @power_up_name = power_up_name
  end

  def call
    return 0 unless @correct

    raw_points = ScoreCalculator.call(
      correct: @correct,
      response_time_ms: @response_time_ms
    )

    modifier = PowerUps::ScoreModifiers.for(@power_up_name)
    points = modifier.apply(raw_points, correct: @correct)

    @player.increment!(:score, points)
    points
  end
end
