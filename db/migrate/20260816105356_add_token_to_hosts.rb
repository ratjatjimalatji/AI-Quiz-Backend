class AddTokenToHosts < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:hosts, :token)
      add_column :hosts, :token, :string, null: false
    end
  end
end
