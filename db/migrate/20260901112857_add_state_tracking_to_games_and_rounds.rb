class AddStateTrackingToGamesAndRounds < ActiveRecord::Migration[8.1]
  def change
    add_reference :games, :current_round, foreign_key: { to_table: :rounds }, index: true
    add_reference :games, :current_question, foreign_key: { to_table: :questions }, index: true
    add_column :games, :question_started_at, :datetime

    add_column :rounds, :position, :integer, default: 0
    add_index :rounds, [ :game_id, :position ]
  end
end
