class AddHostToGames < ActiveRecord::Migration[8.1]
  def change
    add_reference :games, :host, foreign_key: true
  end
end
