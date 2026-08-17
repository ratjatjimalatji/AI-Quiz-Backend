class RemoveHostFieldsFromPlayers < ActiveRecord::Migration[8.1]
  def change
    remove_column :players, :is_host, :boolean
    remove_column :players, :email, :string
    remove_column :players, :password_digest, :string
    remove_column :players, :token, :string
  end
end
