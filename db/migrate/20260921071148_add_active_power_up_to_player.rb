class AddActivePowerUpToPlayer < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :active_power_up, :string
    add_column :players, :active_power_up_question_id, :bigint
    add_index :players, :active_power_up_question_id
  end
end
