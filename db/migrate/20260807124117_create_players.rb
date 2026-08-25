class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :username
      t.integer :score, default: 0
      t.boolean :eliminated, default: false

      t.timestamps
    end
  end
end
