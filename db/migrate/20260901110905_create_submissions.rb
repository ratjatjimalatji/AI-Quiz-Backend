class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.references :player, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :round, null: false, foreign_key: true

      t.string :answer, null: false
      t.boolean :correct, null: false, default: false
      t.integer :response_time_ms, null: false
      t.integer :points_awarded, null: false, default: 0

      t.timestamps
    end

    add_index :submissions, [ :player_id, :question_id, :round_id ], unique: true
  end
end
