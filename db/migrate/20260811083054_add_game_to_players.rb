class AddGameToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_reference :players, :game, foreign_key: true
  end
end
