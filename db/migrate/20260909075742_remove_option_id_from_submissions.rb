class RemoveOptionIdFromSubmissions < ActiveRecord::Migration[8.1]
  def change
    remove_reference :submissions, :option, null: false, foreign_key: true
  end
end
