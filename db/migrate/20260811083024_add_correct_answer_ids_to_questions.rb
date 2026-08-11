class AddCorrectAnswerIdsToQuestions < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:questions, :correct_answer_ids)
      add_column :questions, :correct_answer_ids, :json, default: []
    end
  end
end