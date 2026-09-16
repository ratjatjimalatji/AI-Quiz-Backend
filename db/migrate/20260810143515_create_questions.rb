class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions do |t|
      t.string  :title, null: false
      t.integer :question_type, null: false, default: 0
      t.json :correct_option_position, default: []

      t.timestamps
    end
  end
end
