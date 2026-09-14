class AddOptimizedIndexesToGameTables < ActiveRecord::Migration[8.1]
  def change
    add_index :questions, [ :round_id, :position, :id ]
    add_index :players, [ :game_id, :eliminated ]
  end
end
