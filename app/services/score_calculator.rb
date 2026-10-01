class ScoreCalculator
  def initialize(correct:, response_time_ms:)
    @correct = correct
    @response_time_ms = response_time_ms

    @base_score = 100
    @points_lost_per_interval = 2
    @free_time_ms = 5_000
    @interval_ms = 1_000
    @min_score = 75
  end

  def self.call(correct:, response_time_ms:)
    new(correct: correct, response_time_ms: response_time_ms).call
  end

  def call
    return 0 unless @correct
    deduction_time = [ @response_time_ms - @free_time_ms, 0 ].max
    seconds = (deduction_time / @interval_ms.to_f).floor
    score = @base_score - (seconds * @points_lost_per_interval)
    [ score, @min_score ].max
  end
end
