class AddCorrectAnswerIdsToQuestions < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:questions, :correct_option_position)
      add_column :questions, :correct_option_position, :json, default: []
    end
  end
end
