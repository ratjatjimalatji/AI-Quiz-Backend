class AddPositionToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :position, :integer
  end
end
