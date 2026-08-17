class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :game_code
      t.string :status
      t.references :host, null: false, foreign_key: true

      t.timestamps
    end
  end
end
