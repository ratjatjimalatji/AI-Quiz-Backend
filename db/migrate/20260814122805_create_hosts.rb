class CreateHosts < ActiveRecord::Migration[8.1]
  def change
    create_table :hosts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.timestamps
    end

    add_index :hosts, :token, unique: true

    add_reference :games, :host, null: false, foreign_key: true
  end
end
