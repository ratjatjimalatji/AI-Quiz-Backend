class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions do |t|
      t.string  :title, null: false
      t.integer :question_type, null: false, default: 0
      t.integer :correct_answer_ids array:true, default: []
      t.integer :max_score, null: false, default: 1

      t.timestamps
    end
  end
end
