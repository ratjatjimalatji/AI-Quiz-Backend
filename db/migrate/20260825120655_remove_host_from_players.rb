class RemoveHostFromPlayers < ActiveRecord::Migration[8.1]
   def change
    remove_reference :players, :host, foreign_key: true
   end
end
