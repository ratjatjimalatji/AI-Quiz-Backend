class RemoveHostFromGames < ActiveRecord::Migration[8.1]
  def change
    remove_reference :games, :host, null: false, foreign_key: true
  end
end
