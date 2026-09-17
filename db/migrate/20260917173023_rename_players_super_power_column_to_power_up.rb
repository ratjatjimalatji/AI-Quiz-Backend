class RenamePlayersSuperPowerColumnToPowerUp < ActiveRecord::Migration[8.1]
  def change
    rename_column :players, :super_powers, :power_ups
  end
end
