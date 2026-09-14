class AddPlayersCountToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :players_count, :integer, default: 0, null: false
  end
end
