class CreateRounds < ActiveRecord::Migration[8.1]
  def change
    create_table :rounds do |t|
      t.string :title, null: false
      t.integer :round_type, null: false, default: 0 
      t.timestamps
    end
  end
end
