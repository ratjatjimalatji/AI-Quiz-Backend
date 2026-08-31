class AddPlayerDefaults < ActiveRecord::Migration[8.1]
  def change
    change_column_default :players, :score, 0
    change_column_default :players, :eliminated, false
  end
end
