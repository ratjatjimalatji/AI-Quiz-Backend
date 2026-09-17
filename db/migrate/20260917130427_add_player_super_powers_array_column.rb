class AddPlayerSuperPowersArrayColumn < ActiveRecord::Migration[7.1]
  def change
    remove_column :players, :super_powers, :json
    add_column :players, :super_powers, :string, array: true, default: []
  end
end
