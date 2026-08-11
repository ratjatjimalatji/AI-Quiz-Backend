class CreateOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :options do |t|
      t.references :question, null: false, foreign_key: true
      t.string  :text, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :options, [:question_id, :position]
  end
end
