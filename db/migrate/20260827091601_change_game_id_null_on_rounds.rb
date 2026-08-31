class ChangeGameIdNullOnRounds < ActiveRecord::Migration[8.1]
  def change
    change_column_null :rounds, :game_id, true
  end
end
