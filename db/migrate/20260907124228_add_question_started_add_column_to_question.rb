class AddQuestionStartedAddColumnToQuestion < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :shown_at, :datetime
  end
end
