class FixPlayerLimitDefaultOnGames < ActiveRecord::Migration[8.1]
  def change
    change_column_default :games, :player_limit, from: nil, to: 8
    change_column_null :games, :player_limit, false, 8
  end
end
