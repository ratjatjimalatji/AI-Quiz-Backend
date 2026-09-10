class AddAnswerToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :answer, :jsonb
  end
end
