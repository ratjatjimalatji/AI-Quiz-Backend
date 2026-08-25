class MakeHostIdNotNullOnGames < ActiveRecord::Migration[8.1]
  def change
    change_column_null :games, :host_id, false
  end
end
