class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :username
      t.integer :score
      t.boolean :eliminated

      t.timestamps
    end
  end
end
