class PlayerAdvancementService
  class InvalidPlayerCountError < StandardError; end

  def self.call(game)
    new(game).execute
  end

  def initialize(game)
    @game = game
  end

  def execute
    active_players = @game.players
                           .where(eliminated: false)
                           .order(score: :desc, created_at: :asc)
                           .to_a

    active_count = active_players.count

    return active_players if active_count <= 1

    target_advancing_count = (active_count / 2.0).ceil

    active_players.first(target_advancing_count)
  end
end
