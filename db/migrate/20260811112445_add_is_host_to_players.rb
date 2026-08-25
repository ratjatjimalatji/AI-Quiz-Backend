class AddIsHostToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :is_host, :boolean, default: false, null: false
  end
end
