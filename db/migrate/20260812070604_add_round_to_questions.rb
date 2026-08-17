class AddRoundToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_reference :questions, :round, foreign_key: true
  end
end
