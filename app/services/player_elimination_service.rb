class PlayerEliminationService
  class InvalidPlayerCountError < StandardError; end

  def self.call(game, current_round)
    new(game, current_round).execute
  end

  def initialize(game, current_round)
    @game = game
    @current_round = current_round
  end

  def execute
    active_players = @game.players
                           .where(eliminated: false)
                           .order(score: :desc, created_at: :asc)
                           .to_a

    active_count = active_players.count
    return { advancing: active_players, eliminated: [] } if active_count <= 1

    target_advancing_count = (active_count / 2.0).ceil

    advancing_players = active_players.first(target_advancing_count)
    eliminated_players = active_players.drop(target_advancing_count)

    ActiveRecord::Base.transaction do
      Player.where(id: eliminated_players.map(&:id)).update_all(eliminated: true)
    end

    broadcast_elimination_results(advancing_players, eliminated_players)

    { advancing: advancing_players, eliminated: eliminated_players }
  end

  private

  def broadcast_elimination_results(advancing, eliminated)
    ActionCable.server.broadcast(
      "game_room_#{@game.game_code}",
      {
        event: "players_eliminated",
        round_id: @current_round.id,
        round_title: @current_round.title,
        advancing_player_ids: advancing.map(&:id),
        eliminated_players: eliminated.map do |p|
          {
            id: p.id,
            username: p.username,
            final_score: p.score
          }
        end
      }
    )
  end
end
