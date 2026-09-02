class AddTokenToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :token, :string
    add_index :players, :token, unique: true
  end
end
