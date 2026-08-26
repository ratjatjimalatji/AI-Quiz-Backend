class RemoveHostIdFromPlayers < ActiveRecord::Migration[8.1]
  def change
    remove_column :players, :host_id, :integer
  end
end
