class AddPlayerSuperPowersArrayColumn < ActiveRecord::Migration[7.1]
  def change
    remove_column :players, :super_powers, :json
    add_column :players, :power_ups, :string, array: true, default: []
  end
end
