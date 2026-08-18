class AddGameToRounds < ActiveRecord::Migration[8.1]
  def change
    add_reference :rounds, :game, null: false, foreign_key: true
  end
end
