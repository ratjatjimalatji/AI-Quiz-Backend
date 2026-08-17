class AddTokenToHosts < ActiveRecord::Migration[8.1]
  def change
    add_column :hosts, :token, :string, null: false
    add_column :hosts, :name, :string

    add_index :hosts, :token, unique: true
  end
end
