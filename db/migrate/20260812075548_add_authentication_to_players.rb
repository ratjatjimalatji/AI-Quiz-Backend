class AddAuthenticationToPlayers < ActiveRecord::Migration[8.1]
    def change
    add_column :players, :email, :string
    add_column :players, :password_digest, :string
    add_column :players, :token, :string

    add_index :players, :token, unique: true
    add_index :players, :email, unique: true, where: "email IS NOT NULL"

    # Allow game_id to be null so host profiles can exist before game creation
    change_column_null :players, :game_id, true
  end
end
