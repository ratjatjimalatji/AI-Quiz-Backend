class AddPlayerLimitToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :player_limit, :integer
  end
end
