class RenameCorrectAnswerIdsToCorrectOptionPositionInQuestion < ActiveRecord::Migration[8.1]
  def change
    rename_column :questions, :correct_answer_ids, :correct_option_positions
  end
end
