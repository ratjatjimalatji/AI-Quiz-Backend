class RenamePlayersSuperPowerColumnToPowerUp < ActiveRecord::Migration[8.1]
  def change
    rename_column :players, :super_powers, :power_ups if column_exists?(:players, :super_powers)
  end
end
