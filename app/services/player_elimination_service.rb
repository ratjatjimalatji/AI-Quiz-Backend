class PlayerEliminationService
  class InvalidPlayerError < StandardError; end

  def self.call(game, current_round)
    new(game, current_round).execute
  end

  def initialize(game, current_round)
    @game = game
    @current_round = current_round
  end

  def execute
    active_players = @game.players.where(eliminated: false)
    return { advancing: active_players, eliminated: [] } if active_players.count <= 1

    target_advancing_count = (active_players.count / 2.0).ceil
    target_eliminated_count = active_players.count - target_advancing_count

    ranked_players = active_players.sort_by do |player|
      [ -player.score, player.created_at ]
    end

    advancing_players = ranked_players.first(target_advancing_count)
    eliminated_players = ranked_players.last(target_eliminated_count)

    ActiveRecord::Base.transaction do
      eliminated_players.each do |player|
        player.update!(eliminated: true)
      end
    end

    broadcast_elimination_event(advancing_players, eliminated_players)
    {
      advancing: advancing_players,
      eliminated: eliminated_players
    }
  end

  private

  def broadcast_elimination_event(advancing_players, eliminated_players)
    ActionCable.server.broadcast(
      "game_room#{@game.game_code}",
      {
        event: "players_eliminated",
        round_id: @current_round.id,
        round_title: @current_round.title,
        advancing_players: advancing_players.map(&:id),
        eliminated_players: eliminated_players.map do |player|
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
