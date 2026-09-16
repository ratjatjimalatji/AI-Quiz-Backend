class PlayerEliminationService
  def self.call(game:, advancing_players:)
    new(game:, advancing_players:).execute
  end

  def initialize(game:, advancing_players:)
    @game = game
    @advancing_players = advancing_players
  end

  def execute
    active_players = @game.players.where(eliminated: false)

    eliminated_players =
      active_players.where.not(id: @advancing_players.map(&:id)).to_a

    ActiveRecord::Base.transaction do
      Player.where(id: eliminated_players.map(&:id))
            .update_all(eliminated: true)
    end

    eliminated_players
  end
end
