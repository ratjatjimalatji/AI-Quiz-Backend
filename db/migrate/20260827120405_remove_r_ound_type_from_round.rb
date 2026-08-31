class RemoveROundTypeFromRound < ActiveRecord::Migration[8.1]
  def change
    remove_column :rounds, :round_type, :integer
  end
end
