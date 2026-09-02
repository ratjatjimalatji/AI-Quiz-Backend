class AddGameStatusDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :games, :status, "waiting"
  end
end
