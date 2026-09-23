class AddPlayerSuperPowersArrayColumn < ActiveRecord::Migration[8.1]
  def change
    remove_column :players, :super_powers, :json if column_exists?(:players, :super_powers)
    add_column :players, :power_ups, :string, array: true, default: [] unless column_exists?(:players, :power_ups)
  end
end
